import Foundation
import SwiftUI
import AVFoundation
import AudioToolbox

public enum SessionMode: String, CaseIterable, Identifiable {
    case pomodoro25 = "25 мин (Помодоро)"
    case pomodoro45 = "45 мин (Глубокое)"
    case stopwatch = "Секундомер"

    public var id: String { rawValue }

    public var initialSeconds: Int {
        switch self {
        case .pomodoro25: return 25 * 60
        case .pomodoro45: return 45 * 60
        case .stopwatch: return 0
        }
    }
}

@MainActor
public class ReadingSessionManager: ObservableObject {
    public static let shared = ReadingSessionManager()

    @Published public var isRunning: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var currentMode: SessionMode = .pomodoro25
    @Published public var elapsedSeconds: Int = 0
    @Published public var remainingSeconds: Int = 25 * 60
    @Published public var activeBook: Book? = nil
    @Published public var startPage: Int = 0
    @Published public var isAmbientSoundActive: Bool = false
    @Published public var sessionHistory: [ReadingSessionRecord] = []

    private var timer: Timer?
    private var audioEngine: AVAudioEngine?
    private var noiseNode: AVAudioSourceNode?

    private let historyFileName = "ReadingSessionHistory.json"
    private var historyFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(historyFileName)
    }

    private init() {
        loadHistory()
    }

    // MARK: - Управление таймером
    public func startSession(book: Book, mode: SessionMode) {
        self.activeBook = book
        self.startPage = book.pagesRead
        self.currentMode = mode
        self.elapsedSeconds = 0
        self.remainingSeconds = mode.initialSeconds
        self.isRunning = true
        self.isPaused = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.tick()
            }
        }

        if isAmbientSoundActive {
            startAmbientAudio()
        }
    }

    public func pauseSession() {
        isPaused = true
        stopAmbientAudio()
    }

    public func resumeSession() {
        isPaused = false
        if isAmbientSoundActive {
            startAmbientAudio()
        }
    }

    public func stopSession() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        stopAmbientAudio()
    }

    private func tick() {
        guard isRunning && !isPaused else { return }

        elapsedSeconds += 1

        if currentMode != .stopwatch {
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }

            if remainingSeconds == 0 {
                // Таймер Помодоро завершен
                stopSession()
                notifySessionFinished()
            }
        }
    }

    private func notifySessionFinished() {
        AudioServicesPlaySystemSound(1025)
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    // MARK: - Сохранение сессии
    public func completeSession(endPage: Int) -> ReadingSessionRecord? {
        guard let book = activeBook else { return nil }

        let record = ReadingSessionRecord(
            bookId: book.id,
            bookTitle: book.title,
            date: Date(),
            durationSeconds: max(1, elapsedSeconds),
            startPage: startPage,
            endPage: endPage
        )

        sessionHistory.insert(record, at: 0)
        saveHistory()
        stopSession()
        return record
    }

    // MARK: - Звуки природы / Дождь
    public func toggleAmbientSound() {
        isAmbientSoundActive.toggle()
        if isAmbientSoundActive && isRunning && !isPaused {
            startAmbientAudio()
        } else {
            stopAmbientAudio()
        }
    }

    private func startAmbientAudio() {
        stopAmbientAudio()

        #if !targetEnvironment(macCatalyst)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup: \(error)")
        }
        #endif

        do {
            let engine = AVAudioEngine()
            let format = engine.outputNode.outputFormat(forBus: 0)

            // Безопасный генератор мягкого шелеста дождя
            let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buffer in ablPointer {
                    guard let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    for frame in 0..<Int(frameCount) {
                        let white = Float.random(in: -1.0...1.0)
                        let sample = white * 0.03
                        ptr[frame] = sample
                    }
                }
                return noErr
            }

            engine.attach(sourceNode)
            engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
            try engine.start()

            self.audioEngine = engine
            self.noiseNode = sourceNode
        } catch {
            print("Failed to start ambient audio: \(error)")
        }
    }

    private func stopAmbientAudio() {
        audioEngine?.stop()
        if let node = noiseNode {
            audioEngine?.detach(node)
        }
        audioEngine = nil
        noiseNode = nil
    }

    // MARK: - История
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(sessionHistory)
            try data.write(to: historyFileURL, options: .atomic)
        } catch {
            print("Failed to save session history: \(error)")
        }
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: historyFileURL)
            sessionHistory = try JSONDecoder().decode([ReadingSessionRecord].self, from: data)
        } catch {
            print("Failed to load session history: \(error)")
        }
    }
}

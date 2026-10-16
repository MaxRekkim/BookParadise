import Foundation
import AVFoundation
import SwiftUI

public enum SoundscapeType: String, CaseIterable, Identifiable {
    case none = "none"
    case rain = "rain"
    case fireplace = "fireplace"
    case coffeehouse = "coffeehouse"
    case forest = "forest"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .none: return "Тишина"
        case .rain: return "Дождь за окном"
        case .fireplace: return "Камин в библиотеке"
        case .coffeehouse: return "Уютная кофейня"
        case .forest: return "Лесной бриз"
        }
    }

    public var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain.fill"
        case .fireplace: return "flame.fill"
        case .coffeehouse: return "cup.and.saucer.fill"
        case .forest: return "leaf.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .none: return .secondary
        case .rain: return .blue
        case .fireplace: return .orange
        case .coffeehouse: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .forest: return .green
        }
    }
}

@MainActor
public class SoundscapeManager: ObservableObject {
    public static let shared = SoundscapeManager()

    @Published public var currentMode: SoundscapeType = .none
    @Published public var isPlaying: Bool = false
    @Published public var volume: Float = 0.5 {
        didSet {
            engine?.mainMixerNode.outputVolume = volume
        }
    }

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?

    private init() {}

    public func setMode(_ mode: SoundscapeType) {
        if mode == currentMode && isPlaying {
            return
        }

        if mode == .none {
            stop()
            currentMode = .none
            return
        }

        currentMode = mode
        startEngine(for: mode)
    }

    public func togglePlayback() {
        if isPlaying {
            stop()
        } else if currentMode != .none {
            startEngine(for: currentMode)
        } else {
            setMode(.rain)
        }
    }

    public func stop() {
        if let engine = engine, engine.isRunning {
            engine.stop()
        }
        engine = nil
        sourceNode = nil
        isPlaying = false
    }

    private func startEngine(for mode: SoundscapeType) {
        stop()

        do {
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            #endif

            let newEngine = AVAudioEngine()
            let format = newEngine.outputNode.outputFormat(forBus: 0)

            // Процедурный генератор натурального звука (0 байт внешних ассетов)
            var lastSample: Float = 0.0
            var crackleCounter: Int = 0
            var lfoPhase: Float = 0.0

            let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                let sampleRate = Float(format.sampleRate > 0 ? format.sampleRate : 44100.0)

                for frame in 0..<Int(frameCount) {
                    lfoPhase += 1.0 / sampleRate
                    if lfoPhase > 1000.0 { lfoPhase = 0.0 }

                    var sample: Float = 0.0

                    switch mode {
                    case .none:
                        sample = 0.0

                    case .rain:
                        // Фильтрованный коричневый шум + модуляция волн дождя
                        let white = Float.random(in: -1.0...1.0)
                        lastSample = (lastSample + (0.02 * white)) / 1.02
                        let wave = 0.8 + 0.2 * sin(lfoPhase * 0.4)
                        sample = lastSample * 3.5 * wave

                    case .fireplace:
                        // Теплый низкочастотный гул + случайные потрескивания искр
                        let white = Float.random(in: -1.0...1.0)
                        lastSample = (lastSample + (0.015 * white)) / 1.015
                        var crackle: Float = 0.0
                        crackleCounter += 1
                        if crackleCounter > 8000 && Float.random(in: 0...1) < 0.003 {
                            crackle = Float.random(in: 0.3...0.8) * (Float.random(in: 0...1) > 0.5 ? 1 : -1)
                            crackleCounter = 0
                        }
                        sample = (lastSample * 2.5) + crackle

                    case .coffeehouse:
                        // Мягкий рассеянный шум помещения с мягкими обертонами
                        let white = Float.random(in: -1.0...1.0)
                        lastSample = (lastSample + (0.01 * white)) / 1.01
                        let breath = 0.85 + 0.15 * sin(lfoPhase * 0.25)
                        sample = lastSample * 2.8 * breath

                    case .forest:
                        // Шелест листвы и бриз (плавный модулированный розовый шум)
                        let white = Float.random(in: -1.0...1.0)
                        lastSample = (lastSample + (0.03 * white)) / 1.03
                        let wind = 0.7 + 0.3 * sin(lfoPhase * 0.18)
                        sample = lastSample * 3.0 * wind
                    }

                    // Ограничиваем пики
                    let clamped = max(-1.0, min(1.0, sample))

                    for buffer in ablPointer {
                        let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                        buf[frame] = clamped
                    }
                }
                return noErr
            }

            self.sourceNode = node
            self.engine = newEngine

            newEngine.attach(node)
            newEngine.connect(node, to: newEngine.mainMixerNode, format: format)
            newEngine.mainMixerNode.outputVolume = volume

            try newEngine.start()
            isPlaying = true
        } catch {
            print("Failed to start soundscape audio engine: \(error)")
            isPlaying = false
        }
    }
}

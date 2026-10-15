import Foundation
import SwiftUI
import AudioToolbox

@MainActor
public class ReadingSessionManager: ObservableObject {
    public static let shared = ReadingSessionManager()

    @Published public var isRunning: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var elapsedSeconds: Int = 0
    @Published public var activeBook: Book? = nil
    @Published public var startPage: Int = 0
    @Published public var sessionHistory: [ReadingSessionRecord] = []

    private var timer: Timer?

    private let historyFileName = "ReadingSessionHistory.json"
    private var historyFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(historyFileName)
    }

    private init() {
        loadHistory()
    }

    // MARK: - Управление свободным секундомером чтения
    public func startSession(book: Book) {
        self.activeBook = book
        self.startPage = book.pagesRead
        self.elapsedSeconds = 0
        self.isRunning = true
        self.isPaused = false

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
    }

    public func pauseSession() {
        isPaused = true
    }

    public func resumeSession() {
        isPaused = false
    }

    public func stopSession() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isRunning && !isPaused else { return }
        elapsedSeconds += 1
    }

    // MARK: - Завершение сессии и сохранение в журнал
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

    // MARK: - Хранилище истории
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
            self.sessionHistory = try JSONDecoder().decode([ReadingSessionRecord].self, from: data)
        } catch {
            print("Failed to load session history: \(error)")
        }
    }
}

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
    public var sessions: [ReadingSessionRecord] { sessionHistory }

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

    // MARK: - Умный расчет времени до финала книги (Time-to-Finish)
    public var averageSpeedPagesPerHour: Double {
        let validSessions = sessionHistory.filter { $0.durationSeconds >= 60 && $0.pagesRead > 0 }
        if validSessions.isEmpty {
            return 40.0 // Стандартная базовая скорость чтения
        }
        let totalPages = validSessions.reduce(0) { $0 + $1.pagesRead }
        let totalHours = Double(validSessions.reduce(0) { $0 + $1.durationSeconds }) / 3600.0
        guard totalHours > 0 else { return 40.0 }
        let sp = Double(totalPages) / totalHours
        return min(150.0, max(15.0, sp))
    }

    public func estimatedTimeToFinish(remainingPages: Int) -> (hours: Int, minutes: Int, evenings: Int, displayString: String) {
        guard remainingPages > 0 else {
            return (0, 0, 0, "Книга завершена")
        }
        let speed = averageSpeedPagesPerHour
        let totalHours = Double(remainingPages) / speed
        let totalMinutes = max(1, Int(round(totalHours * 60.0)))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        let evenings = max(1, Int(ceil(Double(totalMinutes) / 45.0))) // расчет из сессии 45 мин

        let timeStr: String
        if h > 0 {
            timeStr = m > 0 ? "~\(h) ч \(m) мин" : "~\(h) ч"
        } else {
            timeStr = "~\(m) мин"
        }

        let eveningWord: String
        if evenings % 10 == 1 && evenings % 100 != 11 {
            eveningWord = "\(evenings) вечер"
        } else if [2, 3, 4].contains(evenings % 10) && ![12, 13, 14].contains(evenings % 100) {
            eveningWord = "\(evenings) вечера"
        } else {
            eveningWord = "\(evenings) вечеров"
        }

        let display = "\(timeStr) (около \(eveningWord))"
        return (h, m, evenings, display)
    }

    // MARK: - Аналитика для Reading Wrapped
    public var totalReadingSeconds: Int {
        sessionHistory.reduce(0) { $0 + $1.durationSeconds }
    }

    public var totalPagesReadInSessions: Int {
        sessionHistory.reduce(0) { $0 + $1.pagesRead }
    }

    public var mostActiveWeekdayString: String {
        guard !sessionHistory.isEmpty else { return "Выходные" }
        var counts: [Int: Int] = [:]
        let calendar = Calendar.current
        for s in sessionHistory {
            let weekday = calendar.component(.weekday, from: s.date)
            counts[weekday, default: 0] += 1
        }
        let top = counts.max(by: { $0.value < $1.value })?.key ?? 1
        switch top {
        case 1: return "Воскресенье"
        case 2: return "Понедельник"
        case 3: return "Вторник"
        case 4: return "Среда"
        case 5: return "Четверг"
        case 6: return "Пятница"
        case 7: return "Суббота"
        default: return "Выходные"
        }
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

import Foundation
import SwiftUI
import Combine

@MainActor
public class AchievementManager: ObservableObject {
    public static let shared = AchievementManager()

    @Published public var achievements: [ReadingAchievement] = []
    @Published public var currentStreak: Int = 0
    @Published public var streakShields: Int = 1
    @Published public var isShieldActiveToday: Bool = false
    @Published public var latestUnlocked: ReadingAchievement? = nil

    private let unlockedKey = "UnlockedAchievementIDs"
    private let datesKey = "UnlockedAchievementDates"
    private let shieldsKey = "ReadingStreakShieldsCount"

    private init() {
        loadBaseAchievements()
        loadPersistedState()
        recalculateAll()
    }

    private func loadBaseAchievements() {
        self.achievements = [
            ReadingAchievement(
                id: "streak_7",
                title: "Книжный огонь",
                subtitle: "Читать каждый день 7 дней подряд",
                systemIcon: "flame.fill",
                badgeEmoji: "🔥",
                category: .streak
            ),
            ReadingAchievement(
                id: "streak_30",
                title: "Железная привычка",
                subtitle: "Удерживать стрик чтения 30 дней подряд",
                systemIcon: "bolt.shield.fill",
                badgeEmoji: "🛡️",
                category: .streak
            ),
            ReadingAchievement(
                id: "night_owl",
                title: "Ночной книгочей",
                subtitle: "Завершить сессию чтения между 00:00 и 04:00",
                systemIcon: "moon.stars.fill",
                badgeEmoji: "🦉",
                category: .speed
            ),
            ReadingAchievement(
                id: "sprint_master",
                title: "Читательский спринт",
                subtitle: "Прочитать более 60 страниц за одну сессию",
                systemIcon: "figure.run",
                badgeEmoji: "⚡",
                category: .speed
            ),
            ReadingAchievement(
                id: "tome_conqueror",
                title: "Покоритель талмудов",
                subtitle: "Полностью прочитать книгу объемом от 600 страниц",
                systemIcon: "books.vertical.fill",
                badgeEmoji: "🧱",
                category: .volume
            ),
            ReadingAchievement(
                id: "saga_keeper",
                title: "Хранитель саги",
                subtitle: "Полностью прочитать все книги одного цикла",
                systemIcon: "crown.fill",
                badgeEmoji: "👑",
                category: .collection
            ),
            ReadingAchievement(
                id: "quote_hunter",
                title: "Мастер цитат",
                subtitle: "Сохранить 10 или более цитат из книг",
                systemIcon: "quote.bubble.fill",
                badgeEmoji: "📝",
                category: .collection
            ),
            ReadingAchievement(
                id: "bibliophile",
                title: "Библиофил",
                subtitle: "Собрать в своей библиотеке 50 или более книг",
                systemIcon: "building.columns.fill",
                badgeEmoji: "📚",
                category: .collection
            ),
            ReadingAchievement(
                id: "bingo_sniper",
                title: "Снайпер Бинго",
                subtitle: "Завершить книгу, запланированную в книжном бинго",
                systemIcon: "target",
                badgeEmoji: "🎯",
                category: .bingo
            ),
            ReadingAchievement(
                id: "soundscape_zen",
                title: "Дзен-погружение",
                subtitle: "Провести сессию чтения со звуками природы",
                systemIcon: "headphones",
                badgeEmoji: "🎧",
                category: .speed
            )
        ]
    }

    public var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    public var totalCount: Int {
        achievements.count
    }

    public func recalculateAll() {
        let history = ReadingSessionManager.shared.sessionHistory
        let quotes = QuotesManager.shared.quotes
        let books = LibraryViewModel.shared.books
        let bingo = LibraryViewModel.shared.bingoItems

        // 1. Расчет Стрика и Защиты Стрика
        calculateStreakAndShields(history: history)

        // 2. Оценка условий достижений
        evaluateNightOwl(history: history)
        evaluateSprint(history: history)
        evaluateTome(books: books)
        evaluateSaga(books: books)
        evaluateQuotes(quotes: quotes)
        evaluateBibliophile(books: books)
        evaluateBingo(books: books, bingo: bingo)
        evaluateStreakAchievements()
        evaluateSoundscapeZen()

        savePersistedState()
    }

    // MARK: - Расчет стрика с защитой (Streak Shield)
    private func calculateStreakAndShields(history: [ReadingSessionRecord]) {
        guard !history.isEmpty else {
            self.currentStreak = 0
            return
        }

        let calendar = Calendar.current
        let sessionDates = Set(history.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)

        var streak = 0
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var currentCheckDate = sessionDates.contains(today) ? today : (sessionDates.contains(yesterday) ? yesterday : today)
        var usedShield = false

        while true {
            if sessionDates.contains(currentCheckDate) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: currentCheckDate) else { break }
                currentCheckDate = prev
            } else if !usedShield && streakShields > 0 && streak > 0 {
                // Активация щита защиты стрика!
                usedShield = true
                guard let prev = calendar.date(byAdding: .day, value: -1, to: currentCheckDate) else { break }
                currentCheckDate = prev
            } else {
                break
            }
        }

        self.currentStreak = streak
        self.isShieldActiveToday = usedShield

        // Начисление щитов: 1 щит за каждые 7 дней стрика (максимум 2)
        if streak >= 14 && streakShields < 2 {
            streakShields = 2
        } else if streak >= 7 && streakShields < 1 {
            streakShields = 1
        }
    }

    // MARK: - Индивидуальные проверки ачивок
    private func evaluateNightOwl(history: [ReadingSessionRecord]) {
        let hasNight = history.contains { record in
            let hour = Calendar.current.component(.hour, from: record.date)
            return hour >= 0 && hour < 4
        }
        updateStatus(id: "night_owl", isUnlocked: hasNight, progress: hasNight ? 1.0 : 0.0, progressText: hasNight ? "Получено!" : "0/1")
    }

    private func evaluateSprint(history: [ReadingSessionRecord]) {
        let maxPagesInSession = history.map { max(0, $0.endPage - $0.startPage) }.max() ?? 0
        let unlocked = maxPagesInSession >= 60
        let prog = min(1.0, Double(maxPagesInSession) / 60.0)
        updateStatus(id: "sprint_master", isUnlocked: unlocked, progress: prog, progressText: "\(maxPagesInSession)/60 стр.")
    }

    private func evaluateTome(books: [Book]) {
        let maxCompletedTome = books.filter { $0.status == .read }.map { $0.totalPages }.max() ?? 0
        let unlocked = maxCompletedTome >= 600
        let prog = min(1.0, Double(maxCompletedTome) / 600.0)
        updateStatus(id: "tome_conqueror", isUnlocked: unlocked, progress: prog, progressText: "\(maxCompletedTome)/600 стр.")
    }

    private func evaluateSaga(books: [Book]) {
        let cycles = LibraryViewModel.shared.normalizedCycles
        let completedCycle = cycles.contains { $0.isCompleted }
        updateStatus(id: "saga_keeper", isUnlocked: completedCycle, progress: completedCycle ? 1.0 : 0.0, progressText: completedCycle ? "Завершено!" : "0/1 циклов")
    }

    private func evaluateQuotes(quotes: [BookQuote]) {
        let count = quotes.count
        let unlocked = count >= 10
        let prog = min(1.0, Double(count) / 10.0)
        updateStatus(id: "quote_hunter", isUnlocked: unlocked, progress: prog, progressText: "\(count)/10 цитат")
    }

    private func evaluateBibliophile(books: [Book]) {
        let count = books.count
        let unlocked = count >= 50
        let prog = min(1.0, Double(count) / 50.0)
        updateStatus(id: "bibliophile", isUnlocked: unlocked, progress: prog, progressText: "\(count)/50 книг")
    }

    private func evaluateBingo(books: [Book], bingo: [BingoItem]) {
        let completedBingo = bingo.contains { item in
            if let book = books.first(where: { $0.id == item.id || $0.title == item.title }) {
                return book.status == .read
            }
            return false
        }
        updateStatus(id: "bingo_sniper", isUnlocked: completedBingo, progress: completedBingo ? 1.0 : 0.0, progressText: completedBingo ? "Выполнено!" : "0/1 планов")
    }

    private func evaluateStreakAchievements() {
        let s7 = currentStreak >= 7
        let p7 = min(1.0, Double(currentStreak) / 7.0)
        updateStatus(id: "streak_7", isUnlocked: s7, progress: p7, progressText: "\(min(7, currentStreak))/7 дней")

        let s30 = currentStreak >= 30
        let p30 = min(1.0, Double(currentStreak) / 30.0)
        updateStatus(id: "streak_30", isUnlocked: s30, progress: p30, progressText: "\(min(30, currentStreak))/30 дней")
    }

    private func evaluateSoundscapeZen() {
        let hasZen = SoundscapeManager.shared.currentMode != .none || UserDefaults.standard.bool(forKey: "UsedSoundscapeBefore")
        updateStatus(id: "soundscape_zen", isUnlocked: hasZen, progress: hasZen ? 1.0 : 0.0, progressText: hasZen ? "Получено!" : "0/1")
    }

    public func markSoundscapeUsed() {
        UserDefaults.standard.set(true, forKey: "UsedSoundscapeBefore")
        evaluateSoundscapeZen()
    }

    private func updateStatus(id: String, isUnlocked: Bool, progress: Double, progressText: String) {
        guard let idx = achievements.firstIndex(where: { $0.id == id }) else { return }
        let wasUnlocked = achievements[idx].isUnlocked

        achievements[idx].progress = progress
        achievements[idx].progressText = progressText

        if isUnlocked && !wasUnlocked {
            achievements[idx].isUnlocked = true
            achievements[idx].unlockedDate = Date()
            self.latestUnlocked = achievements[idx]
        }
    }

    // MARK: - Сохранение состояния
    private func savePersistedState() {
        var unlockedMap: [String: Double] = [:]
        for a in achievements where a.isUnlocked {
            unlockedMap[a.id] = (a.unlockedDate ?? Date()).timeIntervalSince1970
        }
        UserDefaults.standard.set(unlockedMap, forKey: datesKey)
        UserDefaults.standard.set(streakShields, forKey: shieldsKey)
    }

    private func loadPersistedState() {
        self.streakShields = UserDefaults.standard.integer(forKey: shieldsKey)
        if streakShields == 0 {
            streakShields = 1 // Начальный подарочный щит читателя
        }

        if let datesMap = UserDefaults.standard.dictionary(forKey: datesKey) as? [String: Double] {
            for (id, timestamp) in datesMap {
                if let idx = achievements.firstIndex(where: { $0.id == id }) {
                    achievements[idx].isUnlocked = true
                    achievements[idx].unlockedDate = Date(timeIntervalSince1970: timestamp)
                    achievements[idx].progress = 1.0
                }
            }
        }
    }
}

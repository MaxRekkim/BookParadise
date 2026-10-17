import Foundation
import SwiftUI

@MainActor
public class StreakManager: ObservableObject {
    public static let shared = StreakManager()
    private let storageKey = "BookParadise_ReadingStreak_v1"

    @Published public private(set) var streak: ReadingStreak

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        return df
    }()

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(ReadingStreak.self, from: data) {
            self.streak = decoded
        } else {
            self.streak = ReadingStreak()
        }
        checkStreakIntegrity()
    }

    public var currentStreak: Int { streak.currentStreak }
    public var bestStreak: Int { streak.bestStreak }
    public var freezes: Int { streak.streakFreezesRemaining }
    public var freezesAvailable: Int { streak.streakFreezesRemaining }
    public var targetPages: Int { streak.dailyTargetPages }
    public var targetMinutes: Int { streak.dailyTargetMinutes }
    public var lastActiveDate: Date? { streak.lastActivityDate }

    public func recordReadingToday() {
        recordActivity(pages: 10, minutes: 15)
    }

    public func restoreFreeze() {
        streak.streakFreezesRemaining = min(4, streak.streakFreezesRemaining + 1)
        save()
    }

    public func resetStreak() {
        streak.currentStreak = 0
        streak.activeDates.removeAll()
        save()
    }

    public var isCompletedToday: Bool {
        let todayStr = dateFormatter.string(from: Date())
        return streak.activeDates.contains(todayStr)
    }

    public func recordActivity(pages: Int = 0, minutes: Int = 0) {
        let today = Date()
        let todayStr = dateFormatter.string(from: today)

        let wasAlreadyActiveToday = streak.activeDates.contains(todayStr)
        streak.activeDates.insert(todayStr)

        if !wasAlreadyActiveToday {
            let calendar = Calendar.current
            if let lastDate = streak.lastActivityDate {
                if calendar.isDateInYesterday(lastDate) {
                    streak.currentStreak += 1
                } else if !calendar.isDateInToday(lastDate) {
                    // Пропущен день: проверяем заморозку
                    let diffDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: today)).day ?? 0
                    if diffDays == 2 && streak.streakFreezesRemaining > 0 {
                        streak.streakFreezesRemaining -= 1
                        streak.currentStreak += 1 // Спасли заморозкой
                    } else {
                        streak.currentStreak = 1
                    }
                }
            } else {
                streak.currentStreak = 1
            }

            // Добавление новой заморозки каждые 7 дней стрика (до макс. 4)
            if streak.currentStreak > 0 && streak.currentStreak % 7 == 0 && streak.streakFreezesRemaining < 4 {
                streak.streakFreezesRemaining += 1
            }

            if streak.currentStreak > streak.bestStreak {
                streak.bestStreak = streak.currentStreak
            }
        }

        streak.lastActivityDate = today
        save()
        HapticManager.shared.success()
    }

    public func checkStreakIntegrity() {
        guard let lastDate = streak.lastActivityDate else { return }
        let calendar = Calendar.current
        let today = Date()

        if calendar.isDateInToday(lastDate) || calendar.isDateInYesterday(lastDate) {
            return
        }

        let diffDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: today)).day ?? 0
        if diffDays == 2 && streak.streakFreezesRemaining > 0 {
            streak.streakFreezesRemaining -= 1
            // Стрик сохранен заморозкой
        } else if diffDays > 1 {
            streak.currentStreak = 0
        }
        save()
    }

    public func setDailyTargets(pages: Int, minutes: Int) {
        streak.dailyTargetPages = max(1, pages)
        streak.dailyTargetMinutes = max(1, minutes)
        save()
    }

    public func isDateActive(_ date: Date) -> Bool {
        let key = dateFormatter.string(from: date)
        return streak.activeDates.contains(key)
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(streak) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

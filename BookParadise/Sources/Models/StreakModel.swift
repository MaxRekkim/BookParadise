import Foundation

public struct ReadingStreak: Codable {
    public var currentStreak: Int
    public var bestStreak: Int
    public var lastActivityDate: Date?
    public var streakFreezesRemaining: Int
    public var dailyTargetMinutes: Int
    public var dailyTargetPages: Int
    public var activeDates: Set<String> // Формат "yyyy-MM-dd"

    public init(
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        lastActivityDate: Date? = nil,
        streakFreezesRemaining: Int = 2,
        dailyTargetMinutes: Int = 20,
        dailyTargetPages: Int = 15,
        activeDates: Set<String> = []
    ) {
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastActivityDate = lastActivityDate
        self.streakFreezesRemaining = streakFreezesRemaining
        self.dailyTargetMinutes = dailyTargetMinutes
        self.dailyTargetPages = dailyTargetPages
        self.activeDates = activeDates
    }
}

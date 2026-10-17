import Foundation
import SwiftUI

// MARK: - Модель сводки святилища чтения 4.0 (The Sovereign Reading Sanctuary)
public struct SanctuaryMasterStats: Codable, Equatable {
    public var versionString: String
    public var totalBooksInLibrary: Int
    public var totalPagesCompleted: Int
    public var totalReadingHours: Double
    public var shannonEntropy: Double
    public var masterAchievementsUnlocked: Int
    
    public init(
        versionString: String = "4.0.0",
        totalBooksInLibrary: Int = 42,
        totalPagesCompleted: Int = 14200,
        totalReadingHours: Double = 417.6,
        shannonEntropy: Double = 0.88,
        masterAchievementsUnlocked: Int = 12
    ) {
        self.versionString = versionString
        self.totalBooksInLibrary = totalBooksInLibrary
        self.totalPagesCompleted = totalPagesCompleted
        self.totalReadingHours = totalReadingHours
        self.shannonEntropy = shannonEntropy
        self.masterAchievementsUnlocked = masterAchievementsUnlocked
    }
}

import Foundation
import SwiftUI

public enum AchievementCategory: String, Codable, CaseIterable, Identifiable {
    case streak = "streak"
    case volume = "volume"
    case speed = "speed"
    case collection = "collection"
    case bingo = "bingo"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .streak: return "Стрики и постоянство"
        case .volume: return "Объемы и талмуды"
        case .speed: return "Скорость и фокус"
        case .collection: return "Коллекция и заметки"
        case .bingo: return "Книжное бинго"
        }
    }

    public var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .volume: return "books.vertical.fill"
        case .speed: return "bolt.fill"
        case .collection: return "quote.bubble.fill"
        case .bingo: return "checkerboard.rectangle"
        }
    }
}

public struct ReadingAchievement: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemIcon: String
    public let badgeEmoji: String
    public let category: AchievementCategory
    public var isUnlocked: Bool
    public var unlockedDate: Date?
    public var progress: Double // 0.0 ... 1.0
    public var progressText: String

    public init(
        id: String,
        title: String,
        subtitle: String,
        systemIcon: String,
        badgeEmoji: String,
        category: AchievementCategory,
        isUnlocked: Bool = false,
        unlockedDate: Date? = nil,
        progress: Double = 0.0,
        progressText: String = ""
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.badgeEmoji = badgeEmoji
        self.category = category
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.progress = progress
        self.progressText = progressText
    }
}

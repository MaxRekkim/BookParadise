import Foundation
import SwiftUI

// MARK: - Ранг трофея Пантеона Славы
public enum PantheonTier: String, CaseIterable, Identifiable, Codable {
    case bronze = "Бронза"
    case silver = "Серебро"
    case gold = "Золото"
    case platinum = "Платина"
    case obsidian = "Обсидиан"
    
    public var id: String { rawValue }
    
    public var gradientColors: [Color] {
        switch self {
        case .bronze: return [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.35, blue: 0.15)]
        case .silver: return [Color(white: 0.85), Color(white: 0.65)]
        case .gold: return [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.85, green: 0.65, blue: 0.0)]
        case .platinum: return [Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 0.7, green: 0.8, blue: 0.9)]
        case .obsidian: return [Color(red: 0.2, green: 0.15, blue: 0.3), Color(red: 0.05, green: 0.05, blue: 0.1)]
        }
    }
}

// MARK: - Трофей Пантеона
public struct PantheonTrophy: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var description: String
    public var tier: PantheonTier
    public var iconName: String
    public var isUnlocked: Bool
    public var progressPercent: Double
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        tier: PantheonTier,
        iconName: String,
        isUnlocked: Bool = true,
        progressPercent: Double = 100.0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.tier = tier
        self.iconName = iconName
        self.isUnlocked = isUnlocked
        self.progressPercent = progressPercent
    }
}

// MARK: - Каталог Пантеона Славы
public struct LiteraryPantheonCatalog {
    public static var defaultTrophies: [PantheonTrophy] {
        [
            PantheonTrophy(
                title: "Полимат",
                description: "Прочитано не менее 10 книг из 7 разных жанров",
                tier: .obsidian,
                iconName: "crown.fill"
            ),
            PantheonTrophy(
                title: "Центурион Слова",
                description: "Более 100 часов глубокого погружения в чтение",
                tier: .platinum,
                iconName: "hourglass.badge.plus"
            ),
            PantheonTrophy(
                title: "Ночной Философ",
                description: "50 сессий в тишине после полуночи",
                tier: .gold,
                iconName: "moon.stars.fill"
            ),
            PantheonTrophy(
                title: "Хранитель Цитат",
                description: "Собрана коллекция из более чем 100 цитат",
                tier: .gold,
                iconName: "quote.opening"
            )
        ]
    }
}

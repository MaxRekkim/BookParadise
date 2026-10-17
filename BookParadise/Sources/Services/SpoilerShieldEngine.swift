import Foundation
import SwiftUI

// MARK: - Категории литературных спойлеров
public enum SpoilerCategory: String, Codable, CaseIterable {
    case characterFate = "Судьба персонажа"
    case plotTwist = "Поворот сюжета"
    case murdererIdentity = "Личность преступника"
    case finalEnding = "Развязка и финал"
    case sensitiveContent = "Специфический контент"
    
    public var iconName: String {
        switch self {
        case .characterFate: return "heart.slash.fill"
        case .plotTwist: return "bolt.shield.fill"
        case .murdererIdentity: return "person.crop.circle.badge.questionmark"
        case .finalEnding: return "flag.checkered"
        case .sensitiveContent: return "exclamationmark.octagon.fill"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .characterFate: return .red
        case .plotTwist: return .purple
        case .murdererIdentity: return .orange
        case .finalEnding: return .indigo
        case .sensitiveContent: return .yellow
        }
    }
}

// MARK: - Результат анализа текста на спойлеры
public struct SpoilerDetectionResult: Equatable {
    public let hasSpoiler: Bool
    public let confidenceScore: Double // 0.0 ... 1.0
    public let matchedKeywords: [String]
    public let primaryCategory: SpoilerCategory?
    
    public var recommendedBadge: String {
        if let cat = primaryCategory {
            return "⚠️ Спойлер: \(cat.rawValue)"
        }
        return "⚠️ Возможен спойлер"
    }
    
    public static var safe: SpoilerDetectionResult {
        SpoilerDetectionResult(hasSpoiler: false, confidenceScore: 0.0, matchedKeywords: [], primaryCategory: nil)
    }
}

// MARK: - Эвристический анализатор текста SpoilerShieldEngine
public struct SpoilerShieldEngine {
    private static let deathKeywords: [String] = [
        "умирает", "умер", "погибнет", "погибает", "убили", "убийство", "смерть",
        "казнен", "самоубийство", "dies", "death", "killed", "murdered"
    ]
    
    private static let twistKeywords: [String] = [
        "убийца — это", "убийцей оказался", "предатель", "на самом деле жив",
        "оказался жив", "главный злодей", "неожиданный поворот", "вот это поворот",
        "plot twist", "killer is", "traitor", "actually alive"
    ]
    
    private static let endingKeywords: [String] = [
        "в финале", "в конце книги", "концовка", "развязка сюжета", "в последней главе",
        "в эпилоге", "чем закончилось", "ending reveals", "final chapter", "in the end"
    ]
    
    /// Анализирует текст и возвращает структурированный вердикт о наличии спойлеров
    public static func analyzeText(_ text: String) -> SpoilerDetectionResult {
        let lower = text.lowercased()
        guard !lower.isEmpty else { return .safe }
        
        var matches: [String] = []
        var detectedCategory: SpoilerCategory? = nil
        var score: Double = 0.0
        
        // 1. Проверка личность преступника / вот это поворот
        for kw in twistKeywords where lower.contains(kw) {
            matches.append(kw)
            detectedCategory = .plotTwist
            score += 0.5
        }
        
        // 2. Проверка судьба персонажа
        for kw in deathKeywords where lower.contains(kw) {
            matches.append(kw)
            if detectedCategory == nil { detectedCategory = .characterFate }
            score += 0.4
        }
        
        // 3. Проверка финала книги
        for kw in endingKeywords where lower.contains(kw) {
            matches.append(kw)
            if detectedCategory == nil { detectedCategory = .finalEnding }
            score += 0.35
        }
        
        let finalScore = min(1.0, score)
        let isSpoiler = finalScore >= 0.35
        
        return SpoilerDetectionResult(
            hasSpoiler: isSpoiler,
            confidenceScore: finalScore,
            matchedKeywords: matches,
            primaryCategory: isSpoiler ? (detectedCategory ?? .plotTwist) : nil
        )
    }
}

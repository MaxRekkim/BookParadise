import Foundation
import SwiftUI

// MARK: - Литературный мотив
public enum LiteraryMotifCategory: String, Codable, CaseIterable {
    case freeWillVsFate = "Свобода воли и Фатум"
    case solitudeAndExistentialism = "Одиночество и Экзистенция"
    case powerAndMorality = "Власть и Моральный выбор"
    case memoryAndTime = "Время и Ускользающая память"
    case loveAndSacrifice = "Любовь и Самопожертвование"
    
    public var accentColor: Color {
        switch self {
        case .freeWillVsFate: return .orange
        case .solitudeAndExistentialism: return .purple
        case .powerAndMorality: return .red
        case .memoryAndTime: return .blue
        case .loveAndSacrifice: return .pink
        }
    }
    
    public var iconName: String {
        switch self {
        case .freeWillVsFate: return "scale.3d"
        case .solitudeAndExistentialism: return "figure.walk"
        case .powerAndMorality: return "crown.fill"
        case .memoryAndTime: return "hourglass"
        case .loveAndSacrifice: return "heart.fill"
        }
    }
}

// MARK: - Аннотированная цитата для семантического графа
public struct SemanticQuote: Identifiable, Codable, Equatable {
    public let id: UUID
    public var text: String
    public var author: String
    public var bookTitle: String
    public var motif: LiteraryMotifCategory
    public var keywords: Set<String>
    public var pageNumber: Int
    
    public init(
        id: UUID = UUID(),
        text: String,
        author: String,
        bookTitle: String,
        motif: LiteraryMotifCategory,
        keywords: Set<String>,
        pageNumber: Int = 1
    ) {
        self.id = id
        self.text = text
        self.author = author
        self.bookTitle = bookTitle
        self.motif = motif
        self.keywords = keywords
        self.pageNumber = pageNumber
    }
    
    // Коэффициент сходства Жаккара: J(A, B) = |A ∩ B| / |A ∪ B|
    public func jaccardSimilarity(with other: SemanticQuote) -> Double {
        let intersection = keywords.intersection(other.keywords).count
        let union = keywords.union(other.keywords).count
        guard union > 0 else { return 0.0 }
        return Double(intersection) / Double(union)
    }
}

// MARK: - Диалектическая пара (диалог двух авторов)
public struct DialecticQuotePair: Identifiable, Codable, Equatable {
    public let id: UUID
    public var thesis: SemanticQuote
    public var antithesis: SemanticQuote
    public var motif: LiteraryMotifCategory
    public var synthesisCommentary: String
    
    public init(
        id: UUID = UUID(),
        thesis: SemanticQuote,
        antithesis: SemanticQuote,
        motif: LiteraryMotifCategory,
        synthesisCommentary: String
    ) {
        self.id = id
        self.thesis = thesis
        self.antithesis = antithesis
        self.motif = motif
        self.synthesisCommentary = synthesisCommentary
    }
}

// MARK: - Семантический кластер мотивов
public struct SemanticMotifCluster: Identifiable, Codable, Equatable {
    public let id: UUID
    public var motif: LiteraryMotifCategory
    public var quotes: [SemanticQuote]
    
    public init(
        id: UUID = UUID(),
        motif: LiteraryMotifCategory,
        quotes: [SemanticQuote]
    ) {
        self.id = id
        self.motif = motif
        self.quotes = quotes
    }
}

// MARK: - Движок семантической кластеризации
public struct QuoteSemanticClusterEngine {
    
    public static func clusterQuotes(_ quotes: [SemanticQuote]) -> [SemanticMotifCluster] {
        var groups: [LiteraryMotifCategory: [SemanticQuote]] = [:]
        for q in quotes {
            groups[q.motif, default: []].append(q)
        }
        
        return LiteraryMotifCategory.allCases.compactMap { motif in
            guard let list = groups[motif], !list.isEmpty else { return nil }
            return SemanticMotifCluster(motif: motif, quotes: list)
        }
    }
    
    public static var sampleQuotes: [SemanticQuote] {
        [
            SemanticQuote(
                text: "Рукописи не горят.",
                author: "Михаил Булгаков",
                bookTitle: "Мастер и Маргарита",
                motif: .solitudeAndExistentialism,
                keywords: ["рукописи", "память", "бессмертие", "творчество", "огонь"],
                pageNumber: 287
            ),
            SemanticQuote(
                text: "Красота спасёт мир.",
                author: "Фёдор Достоевский",
                bookTitle: "Идиот",
                motif: .loveAndSacrifice,
                keywords: ["красота", "мир", "спасение", "душа", "мораль"],
                pageNumber: 420
            ),
            SemanticQuote(
                text: "Человек осужден быть свободным; потому что, однажды брошенный в мир, он отвечает за все, что делает.",
                author: "Жан-Поль Сартр",
                bookTitle: "Бытие и ничто",
                motif: .freeWillVsFate,
                keywords: ["свобода", "выбор", "человек", "ответственность", "рок"],
                pageNumber: 156
            ),
            SemanticQuote(
                text: "Трусость, несомненно, один из самых страшных пороков.",
                author: "Михаил Булгаков",
                bookTitle: "Мастер и Маргарита",
                motif: .powerAndMorality,
                keywords: ["трусость", "порок", "власть", "мораль", "пилат"],
                pageNumber: 310
            ),
            SemanticQuote(
                text: "Единственный способ справиться с несвободным миром — стать настолько абсолютно свободным, чтобы само твое существование было актом бунта.",
                author: "Альбер Камю",
                bookTitle: "Бунтующий человек",
                motif: .freeWillVsFate,
                keywords: ["свобода", "бунт", "мир", "выбор", "человек"],
                pageNumber: 92
            ),
            SemanticQuote(
                text: "Мы вопрошаем память, но находим лишь эхо забытых теней.",
                author: "Марсель Пруст",
                bookTitle: "В поисках утраченного времени",
                motif: .memoryAndTime,
                keywords: ["память", "время", "тени", "эхо", "утрата"],
                pageNumber: 48
            )
        ]
    }
    
    public static var sampleDialecticPairs: [DialecticQuotePair] {
        let qSartre = SemanticQuote(
            text: "Человек осужден быть свободным; однажды брошенный в мир, он отвечает за все.",
            author: "Жан-Поль Сартр",
            bookTitle: "Бытие и ничто",
            motif: .freeWillVsFate,
            keywords: ["свобода", "выбор", "ответственность"]
        )
        let qCamus = SemanticQuote(
            text: "Единственный способ справиться с несвободным миром — стать абсолютно свободным в бунте.",
            author: "Альбер Камю",
            bookTitle: "Бунтующий человек",
            motif: .freeWillVsFate,
            keywords: ["свобода", "бунт", "мир"]
        )
        
        return [
            DialecticQuotePair(
                thesis: qSartre,
                antithesis: qCamus,
                motif: .freeWillVsFate,
                synthesisCommentary: "Сартр видит свободу как бремя неизбежной вины и тотального выбора, тогда как Камю трансформирует её в очищающий эстетический бунт против абсурда."
            )
        ]
    }
}

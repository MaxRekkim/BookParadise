import Foundation
import SwiftUI

// MARK: - Тип литературного влияния
public enum LiteraryInfluenceType: String, Codable, CaseIterable {
    case directInspiration = "Прямое вдохновение"
    case philosophicalPolemic = "Философская полемика"
    case stylisticSuccessor = "Стилистический преемник"
    case thematicEcho = "Тематическое эхо"
    
    public var iconName: String {
        switch self {
        case .directInspiration: return "arrow.turn.down.right"
        case .philosophicalPolemic: return "bolt.horizontal.fill"
        case .stylisticSuccessor: return "paintbrush.pointed.fill"
        case .thematicEcho: return "waveform.path"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .directInspiration: return .orange
        case .philosophicalPolemic: return .red
        case .stylisticSuccessor: return .indigo
        case .thematicEcho: return .teal
        }
    }
}

// MARK: - 6-мерный вектор литературного стиля автора
public struct LiteraryVector: Codable, Equatable {
    public var existentialDepth: Double      // Экзистенциальная глубина (0..1)
    public var psychologicalRealism: Double  // Психологический реализм (0..1)
    public var magicalMysticism: Double      // Магический реализм / Мистицизм (0..1)
    public var socialSatire: Double          // Социальная сатира / Ирония (0..1)
    public var tragicSublimity: Double       // Трагическая возвышенность (0..1)
    public var lyricalRhythm: Double         // Лиричность и ритмика (0..1)
    
    public init(
        existentialDepth: Double,
        psychologicalRealism: Double,
        magicalMysticism: Double,
        socialSatire: Double,
        tragicSublimity: Double,
        lyricalRhythm: Double
    ) {
        self.existentialDepth = min(max(existentialDepth, 0.0), 1.0)
        self.psychologicalRealism = min(max(psychologicalRealism, 0.0), 1.0)
        self.magicalMysticism = min(max(magicalMysticism, 0.0), 1.0)
        self.socialSatire = min(max(socialSatire, 0.0), 1.0)
        self.tragicSublimity = min(max(tragicSublimity, 0.0), 1.0)
        self.lyricalRhythm = min(max(lyricalRhythm, 0.0), 1.0)
    }
    
    public var asArray: [Double] {
        [existentialDepth, psychologicalRealism, magicalMysticism, socialSatire, tragicSublimity, lyricalRhythm]
    }
    
    // Косинусное сходство: Sim(A, B) = (A • B) / (||A|| * ||B||)
    public func cosineSimilarity(to other: LiteraryVector) -> Double {
        let v1 = self.asArray
        let v2 = other.asArray
        
        var dotProduct: Double = 0.0
        var normA: Double = 0.0
        var normB: Double = 0.0
        
        for i in 0..<v1.count {
            dotProduct += v1[i] * v2[i]
            normA += v1[i] * v1[i]
            normB += v2[i] * v2[i]
        }
        
        let denom = sqrt(normA) * sqrt(normB)
        guard denom > 0.00001 else { return 0.0 }
        return dotProduct / denom
    }
}

// MARK: - Узел автора в генеалогии
public struct AuthorInfluenceNode: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var eraString: String
    public var keyMovement: String
    public var flagshipWork: String
    public var vector: LiteraryVector
    
    public init(
        id: UUID = UUID(),
        name: String,
        eraString: String,
        keyMovement: String,
        flagshipWork: String,
        vector: LiteraryVector
    ) {
        self.id = id
        self.name = name
        self.eraString = eraString
        self.keyMovement = keyMovement
        self.flagshipWork = flagshipWork
        self.vector = vector
    }
}

// MARK: - Связь литературного влияния
public struct AuthorInfluenceLink: Identifiable, Codable, Equatable {
    public let id: UUID
    public var sourceAuthorId: UUID
    public var targetAuthorId: UUID
    public var type: LiteraryInfluenceType
    public var strength: Double // 0.1 .. 1.0
    public var historicalContext: String
    
    public init(
        id: UUID = UUID(),
        sourceAuthorId: UUID,
        targetAuthorId: UUID,
        type: LiteraryInfluenceType,
        strength: Double,
        historicalContext: String
    ) {
        self.id = id
        self.sourceAuthorId = sourceAuthorId
        self.targetAuthorId = targetAuthorId
        self.type = type
        self.strength = min(max(strength, 0.1), 1.0)
        self.historicalContext = historicalContext
    }
}

// MARK: - Матрица генеалогии и влияния
public struct AuthorInfluenceMatrix: Identifiable, Codable, Equatable {
    public let id: UUID
    public var centralAuthorName: String
    public var nodes: [AuthorInfluenceNode]
    public var links: [AuthorInfluenceLink]
    
    public init(
        id: UUID = UUID(),
        centralAuthorName: String,
        nodes: [AuthorInfluenceNode] = [],
        links: [AuthorInfluenceLink] = []
    ) {
        self.id = id
        self.centralAuthorName = centralAuthorName
        self.nodes = nodes
        self.links = links
    }
    
    public func node(with id: UUID) -> AuthorInfluenceNode? {
        nodes.first { $0.id == id }
    }
    
    public func predecessors(for authorId: UUID) -> [(author: AuthorInfluenceNode, link: AuthorInfluenceLink)] {
        links.filter { $0.targetAuthorId == authorId }
            .compactMap { link in
                guard let source = node(with: link.sourceAuthorId) else { return nil }
                return (source, link)
            }
    }
    
    public func successors(for authorId: UUID) -> [(author: AuthorInfluenceNode, link: AuthorInfluenceLink)] {
        links.filter { $0.sourceAuthorId == authorId }
            .compactMap { link in
                guard let target = node(with: link.targetAuthorId) else { return nil }
                return (target, link)
            }
    }
    
    public static var sampleBulgakovGenealogy: AuthorInfluenceMatrix {
        let nGogol = AuthorInfluenceNode(
            name: "Николай Гоголь",
            eraString: "1809–1852",
            keyMovement: "Мистический реализм & Гротеск",
            flagshipWork: "Мёртвые души",
            vector: LiteraryVector(existentialDepth: 0.85, psychologicalRealism: 0.75, magicalMysticism: 0.95, socialSatire: 0.98, tragicSublimity: 0.70, lyricalRhythm: 0.88)
        )
        let nDante = AuthorInfluenceNode(
            name: "Данте Алигьери",
            eraString: "1265–1321",
            keyMovement: "Позднее Средневековье / Ренессанс",
            flagshipWork: "Божественная комедия",
            vector: LiteraryVector(existentialDepth: 0.95, psychologicalRealism: 0.60, magicalMysticism: 0.99, socialSatire: 0.65, tragicSublimity: 0.98, lyricalRhythm: 0.95)
        )
        let nGoethe = AuthorInfluenceNode(
            name: "Иоганн Вольфганг фон Гёте",
            eraString: "1749–1832",
            keyMovement: "Веймарский классицизм",
            flagshipWork: "Фауст",
            vector: LiteraryVector(existentialDepth: 0.96, psychologicalRealism: 0.80, magicalMysticism: 0.92, socialSatire: 0.70, tragicSublimity: 0.95, lyricalRhythm: 0.92)
        )
        let nBulgakov = AuthorInfluenceNode(
            name: "Михаил Булгаков",
            eraString: "1891–1940",
            keyMovement: "Магический сатирический реализм",
            flagshipWork: "Мастер и Маргарита",
            vector: LiteraryVector(existentialDepth: 0.92, psychologicalRealism: 0.88, magicalMysticism: 0.94, socialSatire: 0.96, tragicSublimity: 0.90, lyricalRhythm: 0.85)
        )
        let nMarquez = AuthorInfluenceNode(
            name: "Габриэль Гарсиа Маркес",
            eraString: "1927–2014",
            keyMovement: "Латиноамериканский магический реализм",
            flagshipWork: "Сто лет одиночества",
            vector: LiteraryVector(existentialDepth: 0.90, psychologicalRealism: 0.82, magicalMysticism: 0.98, socialSatire: 0.75, tragicSublimity: 0.88, lyricalRhythm: 0.94)
        )
        
        let l1 = AuthorInfluenceLink(
            sourceAuthorId: nGogol.id,
            targetAuthorId: nBulgakov.id,
            type: .stylisticSuccessor,
            strength: 0.95,
            historicalContext: "«Учитель, укрой меня своей чугунной шинелью!» — прямое духовное ученичество Булгакова у Гоголя."
        )
        let l2 = AuthorInfluenceLink(
            sourceAuthorId: nGoethe.id,
            targetAuthorId: nBulgakov.id,
            type: .directInspiration,
            strength: 0.90,
            historicalContext: "Эпиграф к «Мастеру и Маргарите» взят из «Фауста», образ Воланда переосмысляет Мефистофеля."
        )
        let l3 = AuthorInfluenceLink(
            sourceAuthorId: nDante.id,
            targetAuthorId: nBulgakov.id,
            type: .thematicEcho,
            strength: 0.75,
            historicalContext: "Путешествие Маргариты через ад московского бала и вечный приют души."
        )
        let l4 = AuthorInfluenceLink(
            sourceAuthorId: nBulgakov.id,
            targetAuthorId: nMarquez.id,
            type: .thematicEcho,
            strength: 0.82,
            historicalContext: "Слияние бытового реализма и фантастических явлений как повседневной нормы."
        )
        
        return AuthorInfluenceMatrix(
            centralAuthorName: "Михаил Булгаков",
            nodes: [nGogol, nDante, nGoethe, nBulgakov, nMarquez],
            links: [l1, l2, l3, l4]
        )
    }
}

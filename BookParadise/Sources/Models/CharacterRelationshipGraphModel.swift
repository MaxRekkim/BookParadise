import Foundation
import SwiftUI
import Darwin

// MARK: - Роли персонажей
public enum CharacterRole: String, Codable, CaseIterable {
    case protagonist = "Протагонист"
    case antagonist = "Антагонист"
    case mentor = "Наставник"
    case ally = "Союзник"
    case loveInterest = "Возлюбленный"
    case neutral = "Нейтральный"
    
    public var accentColor: Color {
        switch self {
        case .protagonist: return .blue
        case .antagonist: return .red
        case .mentor: return .purple
        case .ally: return .green
        case .loveInterest: return .pink
        case .neutral: return .secondary
        }
    }
    
    public var iconName: String {
        switch self {
        case .protagonist: return "star.fill"
        case .antagonist: return "flame.fill"
        case .mentor: return "graduationcap.fill"
        case .ally: return "shield.checkered"
        case .loveInterest: return "heart.fill"
        case .neutral: return "person.fill"
        }
    }
}

// MARK: - Типы взаимоотношений
public enum RelationshipType: String, Codable, CaseIterable {
    case ally = "Союз"
    case romance = "Любовь"
    case rivalry = "Вражда"
    case family = "Семья"
    case betrayal = "Предательство"
    case mentor = "Ученичество"
    
    public var edgeColor: Color {
        switch self {
        case .ally: return .green
        case .romance: return .pink
        case .rivalry: return .red
        case .family: return .orange
        case .betrayal: return .purple
        case .mentor: return .blue
        }
    }
}

// MARK: - Узел персонажа
public struct CharacterNode: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var alias: String?
    public var role: CharacterRole
    public var faction: String?
    public var isAlive: Bool
    public var avatarInitials: String
    public var x: Double
    public var y: Double
    public var vx: Double
    public var vy: Double
    
    public init(
        id: UUID = UUID(),
        name: String,
        alias: String? = nil,
        role: CharacterRole = .neutral,
        faction: String? = nil,
        isAlive: Bool = true,
        avatarInitials: String? = nil,
        x: Double = 0.0,
        y: Double = 0.0,
        vx: Double = 0.0,
        vy: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.alias = alias
        self.role = role
        self.faction = faction
        self.isAlive = isAlive
        if let ini = avatarInitials {
            self.avatarInitials = ini
        } else {
            let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
            if parts.count >= 2 {
                self.avatarInitials = String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
            } else {
                self.avatarInitials = String(name.prefix(2)).uppercased()
            }
        }
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
    }
}

// MARK: - Связь между персонажами
public struct RelationshipEdge: Identifiable, Codable, Equatable {
    public let id: UUID
    public let sourceId: UUID
    public let targetId: UUID
    public var type: RelationshipType
    public var strength: Double // -1.0 ... +1.0
    public var notes: String?
    
    public init(
        id: UUID = UUID(),
        sourceId: UUID,
        targetId: UUID,
        type: RelationshipType = .ally,
        strength: Double = 0.8,
        notes: String? = nil
    ) {
        self.id = id
        self.sourceId = sourceId
        self.targetId = targetId
        self.type = type
        self.strength = max(-1.0, min(1.0, strength))
        self.notes = notes
    }
}

// MARK: - Симулятор силовой раскладки графа (Force-Directed 2D Physics)
public struct ForceDirectedGraphEngine {
    /// Один шаг физической симуляции (отталкивание Кулона + пружины Гука + вязкое демпфирование)
    public static func stepSimulation(
        nodes: inout [CharacterNode],
        edges: [RelationshipEdge],
        width: Double,
        height: Double,
        repulsionK: Double = 8000.0,
        springK: Double = 0.04,
        restLength: Double = 90.0,
        damping: Double = 0.85
    ) {
        guard nodes.count > 1 else { return }
        let dt = 0.16
        
        // 1. Силы отталкивания между всеми парами узлов
        for i in 0..<nodes.count {
            for j in (i + 1)..<nodes.count {
                let dx = nodes[j].x - nodes[i].x
                let dy = nodes[j].y - nodes[i].y
                var distSq = dx * dx + dy * dy
                if distSq < 1.0 { distSq = 1.0 }
                let dist = Darwin.sqrt(distSq)
                
                let force = repulsionK / distSq
                let fx = (dx / dist) * force
                let fy = (dy / dist) * force
                
                nodes[i].vx -= fx * dt
                nodes[i].vy -= fy * dt
                nodes[j].vx += fx * dt
                nodes[j].vy += fy * dt
            }
        }
        
        // 2. Силы притяжения вдоль связей (пружины Гука)
        for edge in edges {
            guard let i = nodes.firstIndex(where: { $0.id == edge.sourceId }),
                  let j = nodes.firstIndex(where: { $0.id == edge.targetId }) else { continue }
            
            let dx = nodes[j].x - nodes[i].x
            let dy = nodes[j].y - nodes[i].y
            let dist = max(0.1, Darwin.sqrt(dx * dx + dy * dy))
            
            let displacement = dist - restLength
            let force = springK * displacement
            let fx = (dx / dist) * force
            let fy = (dy / dist) * force
            
            nodes[i].vx += fx * dt
            nodes[i].vy += fy * dt
            nodes[j].vx -= fx * dt
            nodes[j].vy -= fy * dt
        }
        
        // 3. Интеграция скоростей и демпфирование с ограничением границ
        let padding = 35.0
        for i in 0..<nodes.count {
            nodes[i].vx *= damping
            nodes[i].vy *= damping
            nodes[i].x += nodes[i].vx
            nodes[i].y += nodes[i].vy
            
            nodes[i].x = max(padding, min(width - padding, nodes[i].x))
            nodes[i].y = max(padding, min(height - padding, nodes[i].y))
        }
    }
}

// MARK: - Граф персонажей книги
public struct BookCharacterGraph: Identifiable, Codable, Equatable {
    public let id: UUID
    public var bookTitle: String
    public var nodes: [CharacterNode]
    public var edges: [RelationshipEdge]
    
    public init(
        id: UUID = UUID(),
        bookTitle: String,
        nodes: [CharacterNode] = [],
        edges: [RelationshipEdge] = []
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.nodes = nodes
        self.edges = edges
    }
    
    // Эталонный граф для демонстрации («Мастер и Маргарита»)
    public static var sampleMasterAndMargarita: BookCharacterGraph {
        let master = CharacterNode(name: "Мастер", alias: "Историк", role: .protagonist, faction: "Москва", x: 140, y: 150)
        let margarita = CharacterNode(name: "Маргарита", alias: "Королева", role: .loveInterest, faction: "Москва", x: 220, y: 150)
        let woland = CharacterNode(name: "Воланд", alias: "Профессор", role: .antagonist, faction: "Свита", x: 180, y: 80)
        let koroviev = CharacterNode(name: "Коровьев", alias: "Фагот", role: .ally, faction: "Свита", x: 100, y: 60)
        let behemoth = CharacterNode(name: "Кот Бегемот", alias: "Шут", role: .ally, faction: "Свита", x: 260, y: 60)
        let pilate = CharacterNode(name: "Понтий Пилат", alias: "Прокуратор", role: .mentor, faction: "Ершалаим", x: 110, y: 240)
        let yeshua = CharacterNode(name: "Иешуа Га-Ноцри", alias: "Бродячий философ", role: .protagonist, faction: "Ершалаим", x: 240, y: 240)
        
        let e1 = RelationshipEdge(sourceId: master.id, targetId: margarita.id, type: .romance, strength: 1.0, notes: "Вечная любовь")
        let e2 = RelationshipEdge(sourceId: woland.id, targetId: koroviev.id, type: .ally, strength: 0.9, notes: "Верный подручный")
        let e3 = RelationshipEdge(sourceId: woland.id, targetId: behemoth.id, type: .ally, strength: 0.9, notes: "Шут и соратник")
        let e4 = RelationshipEdge(sourceId: woland.id, targetId: master.id, type: .mentor, strength: 0.7, notes: "Даровал покой")
        let e5 = RelationshipEdge(sourceId: pilate.id, targetId: yeshua.id, type: .betrayal, strength: -0.5, notes: "Приговорил к казни, раскаялся")
        
        return BookCharacterGraph(
            bookTitle: "Мастер и Маргарита",
            nodes: [master, margarita, woland, koroviev, behemoth, pilate, yeshua],
            edges: [e1, e2, e3, e4, e5]
        )
    }
}

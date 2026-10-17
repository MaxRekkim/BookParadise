import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Scholarly Marginal Symbols
public enum MarginaliaSymbol: String, CaseIterable, Identifiable, Codable {
    case manicule = "☞"
    case epiphany = "✦"
    case question = "⸮"
    case crossRef = "†"
    case notaBene = "NB"
    case asterisk = "※"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .manicule: return "Перст-указатель (Manicule)"
        case .epiphany: return "Озарение (Epiphany)"
        case .question: return "Вопрос мыслителя"
        case .crossRef: return "Перекрестная ссылка"
        case .notaBene: return "Nota Bene (Важно)"
        case .asterisk: return "Герменевтическое примечание"
        }
    }
}

// MARK: - Watercolor Wash Pigments
public enum WatercolorWashColor: String, CaseIterable, Identifiable, Codable {
    case honeyAmber = "Сусальное золото (Охра)"
    case sageGreen = "Шалфейный мох"
    case vermilionRed = "Киноварь (Кармин)"
    case lapisBlue = "Лазурит (Индиго)"
    case violetDusk = "Сумеречный вереск"
    
    public var id: String { rawValue }
    
    public var color: Color {
        switch self {
        case .honeyAmber:
            return Color(red: 0.95, green: 0.78, blue: 0.35)
        case .sageGreen:
            return Color(red: 0.55, green: 0.75, blue: 0.50)
        case .vermilionRed:
            return Color(red: 0.92, green: 0.40, blue: 0.35)
        case .lapisBlue:
            return Color(red: 0.40, green: 0.65, blue: 0.92)
        case .violetDusk:
            return Color(red: 0.72, green: 0.52, blue: 0.85)
        }
    }
}

// MARK: - Handwriting Style
public enum HandwritingStyle: String, CaseIterable, Identifiable, Codable {
    case scholarCursive = "Университетский курсив"
    case calligraphy = "Гусиное перо"
    case fineLiner = "Архивный линер"
    
    public var id: String { rawValue }
    
    public var fontDesign: Font.Design {
        switch self {
        case .scholarCursive: return .serif
        case .calligraphy: return .serif
        case .fineLiner: return .monospaced
        }
    }
}

// MARK: - Marginalia Note
public struct MarginaliaNote: Identifiable, Codable, Equatable {
    public let id: UUID
    public let bookId: Int
    public let pageNumber: Int
    public var yOffsetFraction: Double // 0.0 ... 1.0 along the margin
    public var text: String
    public var symbol: MarginaliaSymbol
    public var washColor: WatercolorWashColor?
    public var handwritingStyle: HandwritingStyle
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        bookId: Int,
        pageNumber: Int,
        yOffsetFraction: Double = 0.25,
        text: String,
        symbol: MarginaliaSymbol = .manicule,
        washColor: WatercolorWashColor? = .honeyAmber,
        handwritingStyle: HandwritingStyle = .scholarCursive,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.pageNumber = pageNumber
        self.yOffsetFraction = min(0.9, max(0.1, yOffsetFraction))
        self.text = text
        self.symbol = symbol
        self.washColor = washColor
        self.handwritingStyle = handwritingStyle
        self.createdAt = createdAt
    }
}

// MARK: - Dog-Ear Corner Model
public struct DogEarCorner: Codable, Equatable {
    public var isFolded: Bool
    public var foldSize: CGFloat // Point size of triangle fold
    public var foldAngleDegrees: Double
    
    public init(isFolded: Bool = false, foldSize: CGFloat = 36.0, foldAngleDegrees: Double = 45.0) {
        self.isFolded = isFolded
        self.foldSize = foldSize
        self.foldAngleDegrees = foldAngleDegrees
    }
}

// MARK: - Marginalia Manager (Sovereign Local Persistence)
public final class MarginaliaManager: ObservableObject {
    public static let shared = MarginaliaManager()
    
    @Published public private(set) var notes: [MarginaliaNote] = []
    @Published public private(set) var dogEars: [String: DogEarCorner] = [:] // key: "\(bookId)_\(pageNumber)"
    
    private let notesKey = "BookParadise_MarginaliaNotes"
    private let dogEarsKey = "BookParadise_DogEars"
    
    private init() {
        loadData()
    }
    
    public func notesFor(bookId: Int, pageNumber: Int) -> [MarginaliaNote] {
        notes.filter { $0.bookId == bookId && $0.pageNumber == pageNumber }
    }
    
    public func isDogEared(bookId: Int, pageNumber: Int) -> Bool {
        let key = "\(bookId)_\(pageNumber)"
        return dogEars[key]?.isFolded ?? false
    }
    
    public func toggleDogEar(bookId: Int, pageNumber: Int) {
        let key = "\(bookId)_\(pageNumber)"
        var current = dogEars[key] ?? DogEarCorner(isFolded: false)
        current.isFolded.toggle()
        dogEars[key] = current
        saveDogEars()
        
        // Haptic feedback
        HapticManager.shared.lightTap()
    }
    
    public func addNote(_ note: MarginaliaNote) {
        notes.append(note)
        saveNotes()
        HapticManager.shared.success()
    }
    
    public func removeNote(id: UUID) {
        notes.removeAll { $0.id == id }
        saveNotes()
    }
    
    public func totalNotesCount() -> Int {
        notes.count
    }
    
    public func totalDogEarsCount() -> Int {
        dogEars.values.filter { $0.isFolded }.count
    }
    
    // MARK: - Persistence
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([MarginaliaNote].self, from: data) {
            self.notes = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: dogEarsKey),
           let decoded = try? JSONDecoder().decode([String: DogEarCorner].self, from: data) {
            self.dogEars = decoded
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func saveDogEars() {
        if let encoded = try? JSONEncoder().encode(dogEars) {
            UserDefaults.standard.set(encoded, forKey: dogEarsKey)
        }
    }
}

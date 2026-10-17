import Foundation
import SwiftUI

/// Художественный стиль графической рамы и геральдики экслибриса
public enum ExLibrisStyle: String, CaseIterable, Identifiable, Codable {
    case renaissanceWoodcut = "renaissanceWoodcut" // Ренессансная гравюра на дереве
    case artNouveau = "artNouveau"                 // Модерн / Серебряный век (лилии и плавные виньетки)
    case baroqueCrest = "baroqueCrest"             // Барочный гербовый картуш с филигранной короной
    case modernistMinimal = "modernistMinimal"     // Академический геометрический минимализм
    case gothicMonastic = "gothicMonastic"         // Готический монастырский скрипторий

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .renaissanceWoodcut: return "Ренессансная гравюра"
        case .artNouveau: return "Серебряный век (Модерн)"
        case .baroqueCrest: return "Барочный герб"
        case .modernistMinimal: return "Строгий минимализм"
        case .gothicMonastic: return "Готический скрипторий"
        }
    }

    public var subtitle: String {
        switch self {
        case .renaissanceWoodcut: return "Арабески, гравюрная штриховка, латинский антиквенный шрифт"
        case .artNouveau: return "Плавные растительные стебли, орнаментальные арки"
        case .baroqueCrest: return "Геральдический щит, виньетки и королевские картуши"
        case .modernistMinimal: return "Четкие геометрические пропорции, чистая типографика"
        case .gothicMonastic: return "Стрельчатые арки соборов, монументальные буквицы"
        }
    }

    public var icon: String {
        switch self {
        case .renaissanceWoodcut: return "seal.fill"
        case .artNouveau: return "leaf.fill"
        case .baroqueCrest: return "crown.fill"
        case .modernistMinimal: return "square.inset.filled"
        case .gothicMonastic: return "building.columns.fill"
        }
    }
}

/// Тип тиснения и материализации книжного знака
public enum ExLibrisEmbossType: String, CaseIterable, Identifiable, Codable {
    case blindEmboss = "blindEmboss" // Блинтовое бескрасочное тиснение (рельефная бумага)
    case goldLeaf = "goldLeaf"       // Горячее сусальное тиснение золотой фольгой
    case inkStamp = "inkStamp"       // Глубокий оттиск типографской краской (бордо/индиго)
    case waxSeal = "waxSeal"         // Сургучная объемная печать

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .blindEmboss: return "Слепой блинт (рельеф)"
        case .goldLeaf: return "Сусальное золото"
        case .inkStamp: return "Винный оттиск"
        case .waxSeal: return "Сургучная печать"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .blindEmboss: return Color(white: 0.35)
        case .goldLeaf: return Color(red: 0.85, green: 0.68, blue: 0.28)
        case .inkStamp: return Color(red: 0.52, green: 0.14, blue: 0.20)
        case .waxSeal: return Color(red: 0.72, green: 0.18, blue: 0.16)
        }
    }

    public var backgroundGradient: LinearGradient {
        switch self {
        case .blindEmboss:
            return LinearGradient(
                colors: [Color(white: 0.94), Color(white: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .goldLeaf:
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.12, blue: 0.08), Color(red: 0.08, green: 0.06, blue: 0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .inkStamp:
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.96, blue: 0.92), Color(red: 0.93, green: 0.90, blue: 0.84)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .waxSeal:
            return LinearGradient(
                colors: [Color(red: 0.96, green: 0.92, blue: 0.86), Color(red: 0.90, green: 0.85, blue: 0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// Модель конфигурации персонального книжного знака читателя (Ex Libris)
public struct ExLibrisConfig: Codable, Equatable {
    public var ownerName: String
    public var monogram: String
    public var motto: String
    public var style: ExLibrisStyle
    public var embossType: ExLibrisEmbossType
    public var establishedYear: Int
    public var isAutoStampEnabled: Bool

    public static let storageKey = "bookparadise.exlibris.config"

    public init(
        ownerName: String = "Библиофил",
        monogram: String = "МЕ",
        motto: String = "Silentium Legentis",
        style: ExLibrisStyle = .renaissanceWoodcut,
        embossType: ExLibrisEmbossType = .goldLeaf,
        establishedYear: Int = 2026,
        isAutoStampEnabled: Bool = true
    ) {
        self.ownerName = ownerName
        self.monogram = monogram
        self.motto = motto
        self.style = style
        self.embossType = embossType
        self.establishedYear = establishedYear
        self.isAutoStampEnabled = isAutoStampEnabled
    }

    /// Предустановленные классические девизы библиофилов
    public static let suggestedMottos: [String] = [
        "Silentium Legentis",                 // Безмолвие читающего
        "Vita Brevis, Ars Longa",            // Жизнь коротка, искусство вечно
        "Nulla Dies Sine Linea",             // Ни дня без строчки
        "Libris Libertas",                   // В книгах — свобода
        "Amor Librorum Nos Unit",            // Любовь к книгам объединяет нас
        "Semper Legere",                     // Всегда читать
        "Veritas Vos Liberabit"              // Истина освободит вас
    ]

    /// Загрузка конфигурации из постоянного хранилища
    public static func load() -> ExLibrisConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(ExLibrisConfig.self, from: data) else {
            return ExLibrisConfig()
        }
        return decoded
    }

    /// Сохранение конфигурации в UserDefaults
    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: ExLibrisConfig.storageKey)
        }
    }
}

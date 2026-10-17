import Foundation
import SwiftUI

// MARK: - Категория сущности мира
public enum LoreEntryCategory: String, Codable, CaseIterable {
    case location = "Локация"
    case faction = "Фракция / Орден"
    case artifact = "Артефакт"
    case metaphysicalConcept = "Концепт / Магия"
    case historicalOrder = "Событие / Указ"
    
    public var accentColor: Color {
        switch self {
        case .location: return .green
        case .faction: return .blue
        case .artifact: return .orange
        case .metaphysicalConcept: return .purple
        case .historicalOrder: return .teal
        }
    }
    
    public var iconName: String {
        switch self {
        case .location: return "map.fill"
        case .faction: return "shield.lefthalf.filled"
        case .artifact: return "wand.and.stars"
        case .metaphysicalConcept: return "sparkles"
        case .historicalOrder: return "scroll.fill"
        }
    }
}

// MARK: - Статус спойлерной блокировки
public enum LoreLockStatus: Equatable {
    case safe
    case locked(safeAtChapter: Int)
}

// MARK: - Запись кодекса / лора
public struct LoreEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var category: LoreEntryCategory
    public var safeChapter: Int
    public var briefSummary: String
    public var deepLore: String
    public var relatedCharacters: [String]
    public var isManuallyUnlocked: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        category: LoreEntryCategory,
        safeChapter: Int,
        briefSummary: String,
        deepLore: String,
        relatedCharacters: [String] = [],
        isManuallyUnlocked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.safeChapter = safeChapter
        self.briefSummary = briefSummary
        self.deepLore = deepLore
        self.relatedCharacters = relatedCharacters
        self.isManuallyUnlocked = isManuallyUnlocked
    }
    
    public func lockStatus(atCurrentChapter currentChapter: Int) -> LoreLockStatus {
        if isManuallyUnlocked || currentChapter >= safeChapter {
            return .safe
        }
        return .locked(safeAtChapter: safeChapter)
    }
}

// MARK: - Хранилище Лора книги
public struct BookLoreVault: Identifiable, Codable, Equatable {
    public let id: UUID
    public var bookTitle: String
    public var currentReaderChapter: Int
    public var entries: [LoreEntry]
    
    public init(
        id: UUID = UUID(),
        bookTitle: String,
        currentReaderChapter: Int = 1,
        entries: [LoreEntry] = []
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.currentReaderChapter = currentReaderChapter
        self.entries = entries
    }
    
    public var unlockedEntriesCount: Int {
        entries.filter {
            switch $0.lockStatus(atCurrentChapter: currentReaderChapter) {
            case .safe: return true
            case .locked: return false
            }
        }.count
    }
    
    public static var sampleMasterAndMargaritaVault: BookLoreVault {
        let e1 = LoreEntry(
            title: "Нехорошая квартирка №50",
            category: .location,
            safeChapter: 1,
            briefSummary: "Квартира на Большой Садовой, 302-бис, из которой загадочно исчезают жильцы.",
            deepLore: "Используется свитой Воланда как земная резиденция для проведения Весеннего бала ста королей через искривление пятимерного пространства.",
            relatedCharacters: ["Воланд", "Степан Лиходеев", "Коровьев"]
        )
        let e2 = LoreEntry(
            title: "Варьете",
            category: .location,
            safeChapter: 12,
            briefSummary: "Московский театр эстрады, где проходит сенсационный сеанс чёрной магии.",
            deepLore: "Место морального разоблачения московского мещанства: денежный дождь и фальшивый парижский дамский магазин.",
            relatedCharacters: ["Бенгальский", "Варенуха", "Римский"]
        )
        let e3 = LoreEntry(
            title: "Крем Азазелло",
            category: .artifact,
            safeChapter: 20,
            briefSummary: "Чудодейственная жёлтая мазь в золотой коробочке с болотным запахом.",
            deepLore: "Дарует Маргарите вечную молодость, невидимость и способность летать на метле в преддверии бала.",
            relatedCharacters: ["Маргарита", "Азазелло", "Наташа"]
        )
        let e4 = LoreEntry(
            title: "Весенний бал полнолуния",
            category: .historicalOrder,
            safeChapter: 23,
            briefSummary: "Ежегодный грандиозный приём, на котором собираются тени грешников и злодеев всех веков.",
            deepLore: "По законам инфернального протокола хозяйкой бала должна быть местная уроженка по имени Маргарита королевской крови.",
            relatedCharacters: ["Воланд", "Маргарита", "Фрида"]
        )
        let e5 = LoreEntry(
            title: "Обитель вечного покоя",
            category: .metaphysicalConcept,
            safeChapter: 32,
            briefSummary: "Тихий приют при свечах для душ, заслуживших не свет, но покой.",
            deepLore: "Мастер не заслужил ослепительного Света, но заслужил Покой — дом с цветущими вишнями, венецианским окном и бессмертной рукописью.",
            relatedCharacters: ["Мастер", "Маргарита", "Левий Матвей"]
        )
        
        return BookLoreVault(
            bookTitle: "Мастер и Маргарита",
            currentReaderChapter: 15,
            entries: [e1, e2, e3, e4, e5]
        )
    }
}

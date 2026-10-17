import Foundation
import SwiftUI

// MARK: - Модель страницы Альманаха Чтения
public struct AlmanacPageModel: Identifiable, Codable, Equatable {
    public let id: UUID
    public var pageIndex: Int
    public var pageTitle: String
    public var subtitle: String
    public var keyHighlights: [String]
    
    public init(
        id: UUID = UUID(),
        pageIndex: Int,
        pageTitle: String,
        subtitle: String,
        keyHighlights: [String] = []
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.pageTitle = pageTitle
        self.subtitle = subtitle
        self.keyHighlights = keyHighlights
    }
}

// MARK: - Генератор Альманаха (ReadingAlmanacPDFGenerator)
public struct ReadingAlmanacPDFGenerator {
    
    public static func generateAnnualAlmanac(year: Int = 2026, totalBooks: Int, totalPages: Int, topGenre: String) -> [AlmanacPageModel] {
        [
            AlmanacPageModel(
                pageIndex: 1,
                pageTitle: "Альманах Чтения \(year)",
                subtitle: "Персональная литературная летопись",
                keyHighlights: ["\(totalBooks) прочитанных книг", "\(totalPages) страниц за год", "Главный жанр: \(topGenre)"]
            ),
            AlmanacPageModel(
                pageIndex: 2,
                pageTitle: "Когнитивная Аналитика",
                subtitle: "Интеллектуальный профиль и темп",
                keyHighlights: ["Средняя скорость: 34 стр/час", "Шенноновское разнообразие: 0.88", "Экономическая ценность: 42 000 ₽"]
            ),
            AlmanacPageModel(
                pageIndex: 3,
                pageTitle: "Зал Литературной Славы",
                subtitle: "Шедевры и главные открытия года",
                keyHighlights: ["«Мастер и Маргарита» — М. Булгаков", "«Идиот» — Ф. Достоевский", "«1984» — Дж. Оруэлл"]
            ),
            AlmanacPageModel(
                pageIndex: 4,
                pageTitle: "Золотая Антология Цитат",
                subtitle: "Мысли, изменившие перспективу",
                keyHighlights: ["«Рукописи не горят.»", "«Красота спасёт мир.»", "«Человек осужден быть свободным.»"]
            )
        ]
    }
}

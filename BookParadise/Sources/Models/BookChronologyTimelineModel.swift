import Foundation
import SwiftUI

// MARK: - Категории событий в хронологии
public enum TimelineEventCategory: String, Codable, CaseIterable {
    case plotClimax = "Кульминация"
    case characterBackstory = "Предыстория"
    case worldRevelation = "Открытие тайн"
    case historicalFact = "Исторический факт"
    
    public var accentColor: Color {
        switch self {
        case .plotClimax: return .orange
        case .characterBackstory: return .purple
        case .worldRevelation: return .blue
        case .historicalFact: return .green
        }
    }
    
    public var iconName: String {
        switch self {
        case .plotClimax: return "bolt.fill"
        case .characterBackstory: return "clock.arrow.circlepath"
        case .worldRevelation: return "eye.fill"
        case .historicalFact: return "scroll.fill"
        }
    }
}

// MARK: - Узел события хронологии
public struct TimelineEvent: Identifiable, Codable, Equatable {
    public let id: UUID
    public var chronologicalIndex: Int
    public var narrativeChapter: Int
    public var narrativePage: Int
    public var inWorldEraString: String
    public var eventTitle: String
    public var eventDescription: String
    public var category: TimelineEventCategory
    public var isFlashback: Bool
    
    public init(
        id: UUID = UUID(),
        chronologicalIndex: Int,
        narrativeChapter: Int,
        narrativePage: Int = 1,
        inWorldEraString: String,
        eventTitle: String,
        eventDescription: String,
        category: TimelineEventCategory = .plotClimax,
        isFlashback: Bool = false
    ) {
        self.id = id
        self.chronologicalIndex = chronologicalIndex
        self.narrativeChapter = narrativeChapter
        self.narrativePage = narrativePage
        self.inWorldEraString = inWorldEraString
        self.eventTitle = eventTitle
        self.eventDescription = eventDescription
        self.category = category
        self.isFlashback = isFlashback
    }
}

// MARK: - Хронологическая шкала книги
public struct BookChronologyTimeline: Identifiable, Codable, Equatable {
    public let id: UUID
    public var bookTitle: String
    public var events: [TimelineEvent]
    
    public init(
        id: UUID = UUID(),
        bookTitle: String,
        events: [TimelineEvent] = []
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.events = events
    }
    
    public var eventsInNarrativeOrder: [TimelineEvent] {
        events.sorted {
            if $0.narrativeChapter != $1.narrativeChapter {
                return $0.narrativeChapter < $1.narrativeChapter
            }
            return $0.narrativePage < $1.narrativePage
        }
    }
    
    public var eventsInChronologicalOrder: [TimelineEvent] {
        events.sorted { $0.chronologicalIndex < $1.chronologicalIndex }
    }
    
    public var flashbackCount: Int {
        events.filter { $0.isFlashback }.count
    }
    
    public static var sampleTimeline: BookChronologyTimeline {
        let e1 = TimelineEvent(
            chronologicalIndex: 1,
            narrativeChapter: 2,
            narrativePage: 38,
            inWorldEraString: "Нисан, 33 г. н.э.",
            eventTitle: "Допрос Иешуа во дворце Ирода",
            eventDescription: "Понтий Пилат проводит закрытый допрос философа Иешуа Га-Ноцри.",
            category: .historicalFact,
            isFlashback: true
        )
        let e2 = TimelineEvent(
            chronologicalIndex: 2,
            narrativeChapter: 1,
            narrativePage: 12,
            inWorldEraString: "Май 1930 г., вечер",
            eventTitle: "Встреча на Патриарших прудах",
            eventDescription: "Берлиоз и Бездомный встречают таинственного иностранца у пруда.",
            category: .plotClimax,
            isFlashback: false
        )
        let e3 = TimelineEvent(
            chronologicalIndex: 3,
            narrativeChapter: 16,
            narrativePage: 194,
            inWorldEraString: "Нисан, 33 г. н.э., полдень",
            eventTitle: "Казнь на Лысой Горе",
            eventDescription: "Левий Матвей следит за приговором и переживает бурю над Иерусалимом.",
            category: .historicalFact,
            isFlashback: true
        )
        let e4 = TimelineEvent(
            chronologicalIndex: 4,
            narrativeChapter: 23,
            narrativePage: 280,
            inWorldEraString: "Май 1930 г., полночь",
            eventTitle: "Великий бал у Сатаны",
            eventDescription: "Маргарита становится королевой весеннего бала ста королей.",
            category: .worldRevelation,
            isFlashback: false
        )
        let e5 = TimelineEvent(
            chronologicalIndex: 5,
            narrativeChapter: 32,
            narrativePage: 380,
            inWorldEraString: "Вне времени",
            eventTitle: "Прощение Пилата и Вечный покой",
            eventDescription: "Мастер освобождает прокуратора фразой: «Свободен! Он ждет тебя!»",
            category: .plotClimax,
            isFlashback: false
        )
        
        return BookChronologyTimeline(
            bookTitle: "Мастер и Маргарита",
            events: [e1, e2, e3, e4, e5]
        )
    }
}

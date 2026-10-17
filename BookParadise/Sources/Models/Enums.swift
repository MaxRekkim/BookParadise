import Foundation
import SwiftUI

// MARK: - 9 Фиксированных Жанров
public enum Genre: String, CaseIterable, Codable, Identifiable {
    case detective = "Детектив"
    case classicProse = "Классическая проза"
    case romanceYA = "Любовный роман / Young Adult"
    case mysticGothic = "Мистика / Готика"
    case psychologicalThriller = "Психологический триллер"
    case modernProse = "Современная проза"
    case sciFiAltHistory = "Фантастика / Альтернативная история"
    case philosophyPsychology = "Философия / Психология / Нон-фикшн"
    case trueCrime = "True Crime / Нон-фикшн о преступлениях"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .detective: return "magnifyingglass"
        case .classicProse: return "text.book.closed.fill"
        case .romanceYA: return "heart.fill"
        case .mysticGothic: return "moon.stars.fill"
        case .psychologicalThriller: return "brain.head.profile"
        case .modernProse: return "book.fill"
        case .sciFiAltHistory: return "globe.americas.fill"
        case .philosophyPsychology: return "lightbulb.fill"
        case .trueCrime: return "shield.lefthalf.filled"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .detective: return .blue
        case .classicProse: return .brown
        case .romanceYA: return .pink
        case .mysticGothic: return .purple
        case .psychologicalThriller: return .indigo
        case .modernProse: return .teal
        case .sciFiAltHistory: return Color(red: 0.28, green: 0.52, blue: 0.70)
        case .philosophyPsychology: return .orange
        case .trueCrime: return .red
        }
    }
}

// MARK: - Статус Чтения (Столбец L)
public enum ReadingStatus: String, CaseIterable, Codable, Identifiable {
    case notStarted = "Не начата"
    case inProgress = "В процессе"
    case read = "Прочитано"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .notStarted: return "clock"
        case .inProgress: return "book.pages"
        case .read: return "checkmark.seal.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .notStarted: return .secondary
        case .inProgress: return .orange
        case .read: return .green
        }
    }
}

// MARK: - На полке (Столбец M)
public enum ShelfStatus: String, CaseIterable, Codable, Identifiable {
    case onShelf = "В наличии"
    case onlineReading = "Онлайн-чтение"
    
    public var id: String { rawValue }
}

// MARK: - Формат книги (Столбец O)
public enum BookFormat: String, CaseIterable, Codable, Identifiable {
    case paper = "Бумажная"
    case electronic = "Электронная"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .paper: return "book"
        case .electronic: return "ipad.and.iphone"
        }
    }
}

// MARK: - Оценка книги (Столбец P)
public enum BookRating: String, CaseIterable, Codable, Identifiable {
    case star1 = "★"
    case star2 = "★★"
    case star3 = "★★★"
    case star4 = "★★★★"
    case star5 = "★★★★★"
    case masterpiece = "Шедевр!"
    
    public var id: String { rawValue }
    
    public var numericScore: Int {
        switch self {
        case .star1: return 1
        case .star2: return 2
        case .star3: return 3
        case .star4: return 4
        case .star5: return 5
        case .masterpiece: return 6
        }
    }
}

// MARK: - Расширенные фильтры библиотеки
public enum CycleFilterMode: String, CaseIterable, Identifiable {
    case all = "Все"
    case onlyCycles = "В цикле"
    case onlyStandalone = "Одиночные"
    public var id: String { rawValue }
}

public enum PageRangeFilter: String, CaseIterable, Identifiable {
    case all = "Любой объём"
    case short = "До 300 стр."
    case medium = "300–600 стр."
    case thick = "Более 600 стр."
    public var id: String { rawValue }
}

public struct BookFilterCriteria: Equatable {
    public var statuses: Set<ReadingStatus> = []
    public var formats: Set<BookFormat> = []
    public var genres: Set<Genre> = []
    public var ratings: Set<BookRating> = []
    public var shelves: Set<ShelfStatus> = []
    public var cycleMode: CycleFilterMode = .all
    public var pageRange: PageRangeFilter = .all
    public var onlyWithFiles: Bool = false

    public init() {}

    public var isActive: Bool {
        !statuses.isEmpty || !formats.isEmpty || !genres.isEmpty || !ratings.isEmpty || !shelves.isEmpty || cycleMode != .all || pageRange != .all || onlyWithFiles
    }

    public var activeCount: Int {
        var count = 0
        if !statuses.isEmpty { count += statuses.count }
        if !formats.isEmpty { count += formats.count }
        if !genres.isEmpty { count += genres.count }
        if !ratings.isEmpty { count += ratings.count }
        if !shelves.isEmpty { count += shelves.count }
        if cycleMode != .all { count += 1 }
        if pageRange != .all { count += 1 }
        if onlyWithFiles { count += 1 }
        return count
    }

    public mutating func reset() {
        statuses.removeAll()
        formats.removeAll()
        genres.removeAll()
        ratings.removeAll()
        shelves.removeAll()
        cycleMode = .all
        pageRange = .all
        onlyWithFiles = false
    }
}


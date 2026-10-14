import Foundation

// MARK: - Элемент Книжного Бинго (Лист «Книжное бинго»)
public struct BingoItem: Identifiable, Codable, Hashable {
    public var id: Int                         // A: №
    public var title: String                   // B: Название
    public var author: String                  // C: Автор
    public var planMonth: String               // D: Месяц планов (ИЮНЬ, ИЮЛЬ, АВГУСТ...)
    public var totalPages: Int                 // E: Всего стр.
    public var startDate: String?              // F: Начало чтения
    public var endDate: String?                // G: Конец чтения
    public var genre: String                   // H: Жанр
    public var speedPagesPerDay: Double?       // I: Фактическая скорость (Стр./день)
    public var sortKey: String?                // K: Технический ключ (Не трогать!!!)
    public var planDays: Int                   // L: План (дней на книгу) (ввод пользователя)
    public var plannedPagesPerDay: Double      // M: Страниц в день по плану

    public init(
        id: Int,
        title: String,
        author: String,
        planMonth: String,
        totalPages: Int,
        startDate: String? = nil,
        endDate: String? = nil,
        genre: String = "",
        speedPagesPerDay: Double? = nil,
        sortKey: String? = nil,
        planDays: Int = 3,
        plannedPagesPerDay: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.planMonth = planMonth.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.totalPages = max(1, totalPages)
        self.startDate = startDate
        self.endDate = endDate
        self.genre = genre
        self.speedPagesPerDay = speedPagesPerDay
        self.sortKey = sortKey
        self.planDays = max(1, planDays)
        self.plannedPagesPerDay = plannedPagesPerDay ?? Double(self.totalPages / self.planDays)
    }

    public var isSpeedAheadOfPlan: Bool {
        guard let speed = speedPagesPerDay, speed > 0 else { return false }
        return speed >= plannedPagesPerDay
    }
}

// MARK: - Книжный Цикл (Серия)
public struct BookCycle: Identifiable, Codable, Hashable {
    public var id: String { name.lowercased() }
    public var name: String                    // Каноническое название серии
    public var totalBooks: Int
    public var readBooks: Int
    public var completionPercent: Double
    public var bookList: [CycleBookReference]

    public init(
        name: String,
        totalBooks: Int = 0,
        readBooks: Int = 0,
        completionPercent: Double = 0.0,
        bookList: [CycleBookReference] = []
    ) {
        self.name = name
        self.totalBooks = totalBooks
        self.readBooks = readBooks
        self.completionPercent = completionPercent
        self.bookList = bookList
    }

    public var isCompleted: Bool {
        return totalBooks > 0 && readBooks >= totalBooks
    }

    public var isInProgress: Bool {
        return readBooks > 0 && readBooks < totalBooks
    }

    public var isNotStarted: Bool {
        return readBooks == 0
    }
}

public struct CycleBookReference: Identifiable, Codable, Hashable {
    public var id: Int
    public var title: String
    public var cycleNumber: String
    public var isRead: Bool
    
    public init(id: Int, title: String, cycleNumber: String, isRead: Bool) {
        self.id = id
        self.title = title
        self.cycleNumber = cycleNumber
        self.isRead = isRead
    }
}

// MARK: - Статистика приложения и аналитика
public struct AppStats: Codable {
    public var totalBooks: Int
    public var readBooks: Int
    public var inProgressBooks: Int
    public var unreadBooks: Int
    public var paperBooks: Int
    public var electronicBooks: Int
    public var totalPagesRead: Int
    public var percentRead: Double
    public var genreCounts: [String: GenreStatItem]
    public var ratingCounts: [String: Int]
    public var monthlyPurchases: [String: Int]

    public init(
        totalBooks: Int = 0,
        readBooks: Int = 0,
        inProgressBooks: Int = 0,
        unreadBooks: Int = 0,
        paperBooks: Int = 0,
        electronicBooks: Int = 0,
        totalPagesRead: Int = 0,
        percentRead: Double = 0.0,
        genreCounts: [String: GenreStatItem] = [:],
        ratingCounts: [String: Int] = [:],
        monthlyPurchases: [String: Int] = [:]
    ) {
        self.totalBooks = totalBooks
        self.readBooks = readBooks
        self.inProgressBooks = inProgressBooks
        self.unreadBooks = unreadBooks
        self.paperBooks = paperBooks
        self.electronicBooks = electronicBooks
        self.totalPagesRead = totalPagesRead
        self.percentRead = percentRead
        self.genreCounts = genreCounts
        self.ratingCounts = ratingCounts
        self.monthlyPurchases = monthlyPurchases
    }
}

public struct GenreStatItem: Codable {
    public var total: Int
    public var read: Int
    
    public init(total: Int, read: Int) {
        self.total = total
        self.read = read
    }
}

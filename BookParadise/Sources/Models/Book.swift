import Foundation

public struct Book: Identifiable, Codable, Hashable {
    public var id: Int                        // A: № (Int)
    public var title: String                  // B: Название книги
    public var author: String                 // C: Автор
    public var edition: String                // D: Издание
    public var isbn: String                   // E: ISBN
    public var cycleNumber: String            // F: Номер в цикле (default "-")
    public var genre: Genre                   // H: Жанр (9 фиксированных значений)
    public var pagesRead: Int                 // I: Прочитано стр.
    public var totalPages: Int                // J: Всего стр.
    public var progressPercent: Double        // K: Процент прочтения (0.0 ... 100.0)
    public var status: ReadingStatus          // L: Статус чтения
    public var shelf: ShelfStatus             // M: На полке
    public var planMonth: String?             // N: ПЛАН ЧТЕНИЯ (ИЮНЬ, ИЮЛЬ, Заброшено, nil)
    public var format: BookFormat             // O: Формат книги (Бумажная, Электронная)
    public var rating: BookRating?            // P: Оценка
    public var cycleName: String              // Q: Название цикла (default "-")
    public var cycleStatus: Double?           // R: Статус цикла (%)
    public var coverURL: String?              // S: Ссылки на обложки
    public var startDate: String?             // T: Начало чтения (YYYY-MM-DD)
    public var endDate: String?               // U: Конец чтения (YYYY-MM-DD)
    public var monthIndex: Int?               // V: Месяц по порядку (1-12)
    public var purchaseDate: String?          // W: Дата покупки (YYYY-MM-DD)

    public init(
        id: Int,
        title: String,
        author: String,
        edition: String = "",
        isbn: String = "",
        cycleNumber: String = "-",
        genre: Genre = .modernProse,
        pagesRead: Int = 0,
        totalPages: Int,
        progressPercent: Double? = nil,
        status: ReadingStatus? = nil,
        shelf: ShelfStatus = .onShelf,
        planMonth: String? = nil,
        format: BookFormat = .paper,
        rating: BookRating? = nil,
        cycleName: String = "-",
        cycleStatus: Double? = nil,
        coverURL: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        monthIndex: Int? = nil,
        purchaseDate: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.edition = edition
        self.isbn = isbn.replacingOccurrences(of: "\n", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.cycleNumber = cycleNumber.isEmpty ? "-" : cycleNumber
        self.genre = genre
        self.pagesRead = max(0, pagesRead)
        self.totalPages = max(1, totalPages)
        
        let calculatedPercent = totalPages > 0 ? (Double(self.pagesRead) / Double(self.totalPages)) * 100.0 : 0.0
        self.progressPercent = progressPercent ?? (round(calculatedPercent * 10) / 10)
        
        if let explicitStatus = status {
            self.status = explicitStatus
        } else {
            if self.pagesRead == 0 {
                self.status = .notStarted
            } else if self.pagesRead >= self.totalPages {
                self.status = .read
            } else {
                self.status = .inProgress
            }
        }
        
        self.shelf = (format == .electronic) ? .onlineReading : shelf
        self.planMonth = planMonth
        self.format = format
        self.rating = rating
        self.cycleName = cycleName.isEmpty ? "-" : cycleName
        self.cycleStatus = cycleStatus
        self.coverURL = coverURL
        self.startDate = startDate
        self.endDate = endDate
        self.monthIndex = monthIndex
        self.purchaseDate = purchaseDate
    }
    
    // MARK: - Вычисляемые свойства для удобства интерфейса
    
    public var remainingPages: Int {
        return max(0, totalPages - pagesRead)
    }
    
    public var hasCycle: Bool {
        return cycleName != "-" && !cycleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var cleanCoverURL: URL? {
        guard let coverURL = coverURL, !coverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return URL(string: coverURL.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    public var displayProgressString: String {
        return String(format: "%.1f%%", progressPercent)
    }
    
    // Безопасное декодирование для совместимости с Google Apps Script JSON
    enum CodingKeys: String, CodingKey {
        case id, title, author, edition, isbn, cycleNumber, genre
        case pagesRead, totalPages, progressPercent, status, shelf
        case planMonth, format, rating, cycleName, cycleStatus
        case coverURL, startDate, endDate, monthIndex, purchaseDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 1
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Без названия"
        author = try container.decodeIfPresent(String.self, forKey: .author) ?? "Неизвестный автор"
        edition = try container.decodeIfPresent(String.self, forKey: .edition) ?? ""
        isbn = try container.decodeIfPresent(String.self, forKey: .isbn) ?? ""
        cycleNumber = try container.decodeIfPresent(String.self, forKey: .cycleNumber) ?? "-"
        
        let genreStr = try container.decodeIfPresent(String.self, forKey: .genre) ?? ""
        genre = Genre(rawValue: genreStr) ?? .modernProse
        
        pagesRead = try container.decodeIfPresent(Int.self, forKey: .pagesRead) ?? 0
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        progressPercent = try container.decodeIfPresent(Double.self, forKey: .progressPercent) ?? 0.0
        
        let statusStr = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        status = ReadingStatus(rawValue: statusStr) ?? (pagesRead >= totalPages ? .read : (pagesRead > 0 ? .inProgress : .notStarted))
        
        let shelfStr = try container.decodeIfPresent(String.self, forKey: .shelf) ?? ""
        shelf = ShelfStatus(rawValue: shelfStr) ?? .onShelf
        
        planMonth = try container.decodeIfPresent(String.self, forKey: .planMonth)
        
        let formatStr = try container.decodeIfPresent(String.self, forKey: .format) ?? ""
        format = BookFormat(rawValue: formatStr) ?? .paper
        
        if let ratingStr = try container.decodeIfPresent(String.self, forKey: .rating), !ratingStr.isEmpty {
            rating = BookRating(rawValue: ratingStr)
        } else {
            rating = nil
        }
        
        cycleName = try container.decodeIfPresent(String.self, forKey: .cycleName) ?? "-"
        cycleStatus = try container.decodeIfPresent(Double.self, forKey: .cycleStatus)
        coverURL = try container.decodeIfPresent(String.self, forKey: .coverURL)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        monthIndex = try container.decodeIfPresent(Int.self, forKey: .monthIndex)
        purchaseDate = try container.decodeIfPresent(String.self, forKey: .purchaseDate)
    }
}

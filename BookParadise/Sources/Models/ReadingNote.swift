import Foundation

public struct ReadingNote: Identifiable, Codable, Equatable {
    public var id: UUID
    public var bookId: Int?
    public var bookTitle: String?
    public var title: String
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date
    public var tags: [String]
    public var isPinned: Bool
    
    public init(
        id: UUID = UUID(),
        bookId: Int? = nil,
        bookTitle: String? = nil,
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.title = title.isEmpty ? "Без названия" : title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.isPinned = isPinned
    }
    
    public var wordCount: Int {
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }
    
    public var readingTimeMinutes: Int {
        // Средняя скорость чтения заметок: ~200 слов/мин
        return max(1, Int(ceil(Double(wordCount) / 200.0)))
    }
    
    public var excerpt: String {
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        if let first = lines.first {
            return first.count > 120 ? String(first.prefix(120)) + "..." : first
        }
        return "Пустая заметка..."
    }
}

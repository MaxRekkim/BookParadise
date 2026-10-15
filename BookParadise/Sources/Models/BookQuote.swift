import Foundation

public struct BookQuote: Identifiable, Codable, Hashable {
    public var id: UUID
    public var bookId: Int
    public var text: String
    public var pageNumber: Int?
    public var dateAdded: Date
    public var note: String?

    public init(
        id: UUID = UUID(),
        bookId: Int,
        text: String,
        pageNumber: Int? = nil,
        dateAdded: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pageNumber = pageNumber
        self.dateAdded = dateAdded
        self.note = note?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

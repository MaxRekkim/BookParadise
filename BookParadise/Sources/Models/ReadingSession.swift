import Foundation

public typealias ReadingSession = ReadingSessionRecord

public struct ReadingSessionRecord: Identifiable, Codable {

    public var id: UUID
    public var bookId: Int
    public var bookTitle: String
    public var date: Date
    public var durationSeconds: Int
    public var startPage: Int
    public var endPage: Int
    public var pagesRead: Int
    public var speedPagesPerHour: Double
    public var durationMinutes: Int { durationSeconds / 60 }

    public init(
        id: UUID = UUID(),
        bookId: Int,
        bookTitle: String,
        date: Date = Date(),
        durationSeconds: Int,
        startPage: Int,
        endPage: Int
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.date = date
        self.durationSeconds = max(1, durationSeconds)
        self.startPage = startPage
        self.endPage = max(startPage, endPage)
        self.pagesRead = max(0, endPage - startPage)
        
        let hours = Double(self.durationSeconds) / 3600.0
        if hours > 0 && self.pagesRead > 0 {
            self.speedPagesPerHour = (Double(self.pagesRead) / hours).rounded()
        } else {
            self.speedPagesPerHour = 0.0
        }
    }
}

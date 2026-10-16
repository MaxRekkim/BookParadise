import Foundation

public enum LendingType: String, Codable, CaseIterable {
    case lentToFriend = "lent"         // Я отдал почитать
    case borrowedFromFriend = "borrowed" // Я взял почитать

    public var title: String {
        switch self {
        case .lentToFriend: return "Одолжена другу"
        case .borrowedFromFriend: return "Взята почитать"
        }
    }

    public var actionPrompt: String {
        switch self {
        case .lentToFriend: return "Кому передана книга"
        case .borrowedFromFriend: return "У кого взята книга"
        }
    }
}

public struct BookLendingRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let bookId: String
    public var bookTitle: String
    public var personName: String
    public var contact: String?
    public var lentDate: Date
    public var dueDate: Date?
    public var isReturned: Bool
    public var returnDate: Date?
    public var notes: String?
    public var type: LendingType

    public init(
        id: UUID = UUID(),
        bookId: String,
        bookTitle: String,
        personName: String,
        contact: String? = nil,
        lentDate: Date = Date(),
        dueDate: Date? = nil,
        isReturned: Bool = false,
        returnDate: Date? = nil,
        notes: String? = nil,
        type: LendingType = .lentToFriend
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.personName = personName
        self.contact = contact
        self.lentDate = lentDate
        self.dueDate = dueDate
        self.isReturned = isReturned
        self.returnDate = returnDate
        self.notes = notes
        self.type = type
    }

    public var isOverdue: Bool {
        guard !isReturned, let due = dueDate else { return false }
        return due < Date()
    }

    public var daysRemaining: Int? {
        guard let due = dueDate else { return nil }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: due).day ?? 0
        return diff
    }
}

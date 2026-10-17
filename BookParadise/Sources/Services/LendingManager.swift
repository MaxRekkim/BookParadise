import Foundation
import SwiftUI

@MainActor
public class LendingManager: ObservableObject {
    public static let shared = LendingManager()

    @Published public var records: [BookLendingRecord] = []

    private let userDefaultsKey = "bp_lending_records_v1"

    private init() {
        load()
    }

    public var activeRecords: [BookLendingRecord] {
        records.filter { !$0.isReturned }
            .sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }

    public var overdueRecords: [BookLendingRecord] {
        activeRecords.filter { $0.isOverdue }
    }

    public func activeLending(for bookId: String) -> BookLendingRecord? {
        records.first { $0.bookId == bookId && !$0.isReturned }
    }

    public func lendBook(
        book: Book,
        personName: String,
        contact: String? = nil,
        dueDate: Date? = nil,
        type: LendingType = .lentToFriend,
        notes: String? = nil
    ) {
        let trimmedName = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Если уже была активная запись для этой книги, помечаем её возвращенной
        let bookIdStr = String(book.id)
        if let existingIndex = records.firstIndex(where: { $0.bookId == bookIdStr && !$0.isReturned }) {
            records[existingIndex].isReturned = true
            records[existingIndex].returnDate = Date()
        }

        let record = BookLendingRecord(
            bookId: bookIdStr,
            bookTitle: book.title,
            personName: trimmedName,
            contact: contact?.trimmingCharacters(in: .whitespacesAndNewlines),
            lentDate: Date(),
            dueDate: dueDate,
            isReturned: false,
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type
        )

        records.insert(record, at: 0)
        save()
    }

    public func markReturned(recordId: UUID) {
        if let idx = records.firstIndex(where: { $0.id == recordId }) {
            records[idx].isReturned = true
            records[idx].returnDate = Date()
            save()
        }
    }

    public func markAsReturned(recordId: UUID) {
        markReturned(recordId: recordId)
    }

    public func deleteRecord(recordId: UUID) {
        records.removeAll { $0.id == recordId }
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save lending records: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            records = try JSONDecoder().decode([BookLendingRecord].self, from: data)
        } catch {
            print("Failed to load lending records: \(error)")
        }
    }
}

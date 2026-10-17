import Foundation
import SwiftUI

@MainActor
public class QuotesManager: ObservableObject {
    public static let shared = QuotesManager()

    @Published public var quotes: [BookQuote] = []

    private let fileName = "BookQuotes.json"

    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }

    private init() {
        loadQuotes()
    }

    public func quotes(for bookId: Int) -> [BookQuote] {
        return quotes.filter { $0.bookId == bookId }.sorted { $0.dateAdded > $1.dateAdded }
    }

    public func addQuote(bookId: Int, text: String, pageNumber: Int?, note: String?) {
        let newQuote = BookQuote(bookId: bookId, text: text, pageNumber: pageNumber, dateAdded: Date(), note: note)
        quotes.insert(newQuote, at: 0)
        saveQuotes()
        AchievementManager.shared.recalculateAll()
        RPGLevelManager.shared.addXP(15, reason: "Новая цитата")
        StreakManager.shared.recordActivity(pages: 1, minutes: 2)
    }

    public func addQuote(text: String, bookTitle: String, author: String, page: Int?, tags: [String]? = nil) {
        let noteString = [author, "«\(bookTitle)»"].joined(separator: " — ")
        let newQuote = BookQuote(bookId: 1, text: text, pageNumber: page, dateAdded: Date(), note: noteString)
        quotes.insert(newQuote, at: 0)
        saveQuotes()
        AchievementManager.shared.recalculateAll()
        RPGLevelManager.shared.addXP(15, reason: "Новая цитата")
        StreakManager.shared.recordActivity(pages: 1, minutes: 2)
    }

    public func deleteQuote(id: UUID) {
        quotes.removeAll { $0.id == id }
        saveQuotes()
        AchievementManager.shared.recalculateAll()
    }

    public func updateQuote(id: UUID, text: String? = nil, pageNumber: Int? = nil, note: String? = nil, clearNote: Bool = false) {
        guard let index = quotes.firstIndex(where: { $0.id == id }) else { return }
        var updated = quotes[index]
        if let text = text { updated.text = text.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let pageNumber = pageNumber { updated.pageNumber = pageNumber }
        if clearNote {
            updated.note = nil
        } else if let note = note {
            updated.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        quotes[index] = updated
        saveQuotes()
    }

    private func saveQuotes() {
        do {
            let data = try JSONEncoder().encode(quotes)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save quotes: \(error)")
        }
    }

    private func loadQuotes() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // Начальные демо-цитаты для первой книги «Дурное поведение» и «Время жить и время умирать»
            self.quotes = [
                BookQuote(
                    bookId: 2,
                    text: "Человек не знает, как много он может забыть, пока не наступит время, когда он должен забыть.",
                    pageNumber: 42,
                    dateAdded: Date(),
                    note: "Очень точная мысль Ремарка о человеческой памяти."
                ),
                BookQuote(
                    bookId: 1,
                    text: "Страх — это самый древний инстинкт, но именно он помогает нам оставаться людьми в критические моменты.",
                    pageNumber: 115,
                    dateAdded: Date(),
                    note: "Мысли Зои Бентли во время расследования."
                )
            ]
            saveQuotes()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            self.quotes = try JSONDecoder().decode([BookQuote].self, from: data)
        } catch {
            print("Failed to load quotes: \(error)")
        }
    }
}

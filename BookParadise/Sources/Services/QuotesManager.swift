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
    }

    public func deleteQuote(id: UUID) {
        quotes.removeAll { $0.id == id }
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

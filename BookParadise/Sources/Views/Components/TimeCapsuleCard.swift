import SwiftUI

public struct TimeCapsuleCard: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    public var onSelectBook: ((Book) -> Void)? = nil

    public init(viewModel: LibraryViewModel, onSelectBook: ((Book) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSelectBook = onSelectBook
    }

    private struct Memory {
        let title: String
        let quoteOrNote: String
        let page: Int?
        let yearAgoText: String
        let book: Book?
    }

    private var todayMemory: Memory? {
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.month, .day], from: Date())

        // 1. Поиск в сохраненных цитатах читателя
        for q in quotesManager.quotes {
            let qComponents = calendar.dateComponents([.year, .month, .day], from: q.dateAdded)
            let currentYear = calendar.component(.year, from: Date())
            let diffYear = currentYear - (qComponents.year ?? currentYear)

            if qComponents.month == todayComponents.month && qComponents.day == todayComponents.day && diffYear > 0 {
                let matchingBook = viewModel.books.first { $0.id == q.bookId }
                let yearText = diffYear == 1 ? "Ровно год назад" : "\(diffYear) года назад"
                return Memory(
                    title: matchingBook?.title ?? "Из ваших цитат",
                    quoteOrNote: q.text,
                    page: q.pageNumber,
                    yearAgoText: yearText,
                    book: matchingBook
                )
            }
        }

        // 2. Если точного совпадения по прошлым годам нет — берем лучшую случайную цитату из базы
        if let randomQuote = quotesManager.quotes.randomElement() {
            let matchingBook = viewModel.books.first { $0.id == randomQuote.bookId }
            return Memory(
                title: matchingBook?.title ?? "Книжное воспоминание",
                quoteOrNote: randomQuote.text,
                page: randomQuote.pageNumber,
                yearAgoText: "Воспоминание из библиотеки",
                book: matchingBook
            )
        }

        return nil
    }

    public var body: some View {
        if let memory = todayMemory {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(theme.primaryAccent)
                        .font(.subheadline)
                    Text("Капсула времени • \(memory.yearAgoText)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryAccent)
                        .textCase(.uppercase)

                    Spacer()

                    if let book = memory.book {
                        Button(action: { onSelectBook?(book) }) {
                            Text("К книге")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primaryAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(theme.primaryAccent.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                }

                Text("«\(memory.quoteOrNote)»")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(3)

                HStack {
                    Text(memory.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    if let page = memory.page {
                        Text("• стр. \(page)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .padding(14)
            .background(theme.cardBackground(for: colorScheme))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
            )
        }
    }
}

import SwiftUI
import UIKit

public struct QuotesGalleryView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var searchText: String = ""
    @State private var selectedQuoteForShare: QuoteShareWrapper? = nil
    @State private var quoteToDelete: BookQuote? = nil
    @State private var showDeleteConfirmation: Bool = false
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    private var filteredQuotes: [(quote: BookQuote, book: Book)] {
        var results: [(quote: BookQuote, book: Book)] = []
        
        for quote in quotesManager.quotes {
            let matchingBook = viewModel.books.first(where: { $0.id == quote.bookId }) ?? Book(
                id: quote.bookId,
                title: "Книга #\(quote.bookId)",
                author: "Автор неизвестен",
                totalPages: 1
            )
            
            if searchText.isEmpty {
                results.append((quote, matchingBook))
            } else {
                let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if quote.text.lowercased().contains(query) ||
                    (quote.note?.lowercased().contains(query) ?? false) ||
                    matchingBook.title.lowercased().contains(query) ||
                    matchingBook.author.lowercased().contains(query) {
                    results.append((quote, matchingBook))
                }
            }
        }
        
        return results
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if filteredQuotes.isEmpty {
                    emptyQuotesView
                } else {
                    quotesScrollView
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Цитаты и заметки (\(quotesManager.quotes.count))")
            .searchable(text: $searchText, prompt: "Поиск по цитатам, авторам, книгам...")
            .sheet(item: $selectedQuoteForShare) { wrapper in
                QuoteCardShareView(quote: wrapper.quote, book: wrapper.book)
            }
            .confirmationDialog("Удалить цитату?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    if let q = quoteToDelete {
                        quotesManager.deleteQuote(id: q.id)
                        quoteToDelete = nil
                    }
                }
                Button("Отмена", role: .cancel) {
                    quoteToDelete = nil
                }
            }
        }
    }
    
    private var quotesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredQuotes, id: \.quote.id) { item in
                    quoteCardView(quote: item.quote, book: item.book)
                }
            }
            .padding()
        }
    }
    
    private func quoteCardView(quote: BookQuote, book: Book) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                BookCoverView(
                    coverURL: book.cleanCoverURL,
                    title: book.title,
                    author: book.author,
                    cornerRadius: 6
                )
                .frame(width: 44, height: 64)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let page = quote.pageNumber, page > 0 {
                        Text("Страница \(page)")
                            .font(.caption2)
                            .foregroundColor(theme.primaryAccent)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: {
                        selectedQuoteForShare = QuoteShareWrapper(quote: quote, book: book)
                    }) {
                        Label("Поделиться карточкой", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        UIPasteboard.general.string = "«\(quote.text)» — \(book.author), «\(book.title)»"
                    }) {
                        Label("Скопировать текст", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        quoteToDelete = quote
                        showDeleteConfirmation = true
                    }) {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
            }
            
            Divider()
            
            Text("«\(quote.text)»")
                .font(.system(.body, design: .serif))
                .italic()
                .lineSpacing(4)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let note = quote.note, !note.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundColor(theme.primaryAccent)
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.primaryAccent.opacity(0.06))
                .cornerRadius(8)
            }
            
            HStack {
                Text(quote.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    selectedQuoteForShare = QuoteShareWrapper(quote: quote, book: book)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Карточка открытка")
                    }
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(theme.primaryAccent.opacity(0.12))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private var emptyQuotesView: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "quote.opening")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryAccent.opacity(0.6))
            Text(searchText.isEmpty ? "Пока нет сохраненных цитат" : "Ничего не найдено")
                .font(.headline)
            Text(searchText.isEmpty ? "Откройте любую книгу и нажмите «Добавить цитату», чтобы отсканировать страницу камерой или записать понравившуюся мысль." : "Попробуйте изменить поисковый запрос.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

public struct QuoteShareWrapper: Identifiable {
    public let id = UUID()
    public let quote: BookQuote
    public let book: Book
    
    public init(quote: BookQuote, book: Book) {
        self.quote = quote
        self.book = book
    }
}

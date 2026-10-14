import SwiftUI

public struct BookDetailView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    public let bookId: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingProgressUpdate: Bool = false
    @State private var isShowingPlanSheet: Bool = false
    
    public init(viewModel: LibraryViewModel, bookId: Int) {
        self.viewModel = viewModel
        self.bookId = bookId
    }
    
    private var book: Book? {
        viewModel.books.first(where: { $0.id == bookId })
    }
    
    public var body: some View {
        Group {
            if let book = book {
                content(for: book)
            } else {
                Text("Книга не найдена")
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func content(for book: Book) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Верхний блок с крупной обложкой
                HStack(alignment: .top, spacing: 18) {
                    BookCoverView(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        genre: book.genre,
                        cornerRadius: 12
                    )
                    .frame(width: 125, height: 185)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.genre.rawValue)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(book.genre.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(book.genre.accentColor.opacity(0.12))
                            .cornerRadius(6)
                        
                        Text(book.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(3)
                        
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let r = book.rating {
                            Text(r.rawValue)
                                .font(.headline)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text(book.status.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(book.status.color)
                                .cornerRadius(8)
                            
                            Text(book.format.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Прогресс чтения
                VStack(spacing: 10) {
                    HStack {
                        Text("Прогресс чтения:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(book.pagesRead) из \(book.totalPages) стр. (\(book.displayProgressString))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    ProgressView(value: Double(book.pagesRead), total: Double(max(1, book.totalPages)))
                        .tint(.orange)
                    
                    HStack(spacing: 12) {
                        Button(action: { isShowingProgressUpdate = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Изменить страницы")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { isShowingPlanSheet = true }) {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("В план бинго")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Серия / Цикл (если есть)
                if book.hasCycle {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bookmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Серия: \(book.cycleName)")
                                .font(.headline)
                            Spacer()
                            Text("№ \(book.cycleNumber)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        
                        if let percent = book.cycleStatus {
                            HStack {
                                Text("Прогресс серии:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f%%", percent))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            ProgressView(value: percent, total: 100.0)
                                .tint(.orange)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                
                // Детальные данные книги
                VStack(spacing: 12) {
                    detailRow(title: "Номер в базе (A)", value: "#\(book.id)")
                    Divider()
                    detailRow(title: "Издание / Серия (D)", value: book.edition.isEmpty ? "—" : book.edition)
                    Divider()
                    detailRow(title: "ISBN (E)", value: book.isbn.isEmpty ? "—" : book.isbn)
                    Divider()
                    detailRow(title: "На полке (M)", value: book.shelf.rawValue)
                    Divider()
                    detailRow(title: "План чтения (N)", value: book.planMonth ?? "—")
                    Divider()
                    detailRow(title: "Начало чтения (T)", value: book.startDate ?? "—")
                    Divider()
                    detailRow(title: "Конец чтения (U)", value: book.endDate ?? "—")
                    Divider()
                    detailRow(title: "Дата покупки (W)", value: book.purchaseDate ?? "—")
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                Spacer(minLength: 30)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(book.title)
        .sheet(isPresented: $isShowingProgressUpdate) {
            ProgressUpdateSheet(viewModel: viewModel, book: book)
        }
        .sheet(isPresented: $isShowingPlanSheet) {
            AddToPlanSheet(viewModel: viewModel, book: book)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

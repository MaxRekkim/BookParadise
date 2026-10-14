import SwiftUI

public struct LibraryView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @State private var bookForProgressUpdate: Book? = nil
    @State private var bookForPlan: Book? = nil
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Строка быстрых фильтров-чипсов
                filterChipsBar
                
                // Сортировка и переключатель вида (Сетка / Список)
                HStack {
                    Menu {
                        Picker("Сортировка", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(viewModel.sortOption.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    
                    // Фильтр по жанру
                    Menu {
                        Button("Все жанры") { viewModel.selectedGenreFilter = nil }
                        Divider()
                        ForEach(Genre.allCases) { g in
                            Button(g.rawValue) { viewModel.selectedGenreFilter = g }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(viewModel.selectedGenreFilter?.rawValue ?? "Жанр")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundColor(viewModel.selectedGenreFilter == nil ? .primary : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Переключатель Сетка / Список
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.isGridMode.toggle()
                        }
                    }) {
                        Image(systemName: viewModel.isGridMode ? "list.bullet" : "square.grid.3x3.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(7)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Контент: Сетка или Список
                if viewModel.isGridMode {
                    booksGrid
                } else {
                    booksList
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Библиотека (\(viewModel.filteredBooks.count))")
            .searchable(text: $viewModel.searchText, prompt: "Поиск по названию, автору, ISBN...")
            .sheet(item: $bookForProgressUpdate) { book in
                ProgressUpdateSheet(viewModel: viewModel, book: book)
            }
            .sheet(item: $bookForPlan) { book in
                AddToPlanSheet(viewModel: viewModel, book: book)
            }
            .refreshable {
                await viewModel.syncWithCloud()
            }
        }
    }
    
    // MARK: - Чипсы быстрых фильтров
    private var filterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StatusFilter.allCases) { filter in
                    let isSelected = viewModel.selectedStatusFilter == filter
                    let count = countForFilter(filter)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.selectedStatusFilter = filter
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(filter.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("(\(count))")
                                .font(.caption2)
                                .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isSelected ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                        .foregroundColor(isSelected ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
    
    private func countForFilter(_ filter: StatusFilter) -> Int {
        switch filter {
        case .all: return viewModel.books.count
        case .inProgress: return viewModel.books.filter { $0.status == .inProgress }.count
        case .unread: return viewModel.books.filter { $0.status == .notStarted }.count
        case .read: return viewModel.books.filter { $0.status == .read }.count
        case .paper: return viewModel.books.filter { $0.format == .paper }.count
        case .electronic: return viewModel.books.filter { $0.format == .electronic }.count
        }
    }
    
    // MARK: - Сетка обложек (3 в ряд как книжная полка)
    private var booksGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                ForEach(viewModel.filteredBooks) { book in
                    NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            ZStack(alignment: .topTrailing) {
                                BookCoverView(
                                    coverURL: book.cleanCoverURL,
                                    title: book.title,
                                    author: book.author,
                                    genre: book.genre,
                                    cornerRadius: 8
                                )
                                
                                if book.status == .read {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(4)
                                        .background(Circle().fill(.white))
                                        .offset(x: -4, y: 4)
                                } else if book.status == .inProgress {
                                    Text("\(Int(book.progressPercent))%")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.orange))
                                        .offset(x: -4, y: 4)
                                }
                            }
                            
                            Text(book.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text(book.author)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .contextMenu {
                        Button(action: { bookForProgressUpdate = book }) {
                            Label("Обновить прогресс", systemImage: "pencil")
                        }
                        Button(action: { bookForPlan = book }) {
                            Label("Добавить в план", systemImage: "calendar.badge.plus")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Компактный список
    private var booksList: some View {
        List {
            ForEach(viewModel.filteredBooks) { book in
                NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                    HStack(spacing: 12) {
                        BookCoverView(
                            coverURL: book.cleanCoverURL,
                            title: book.title,
                            author: book.author,
                            genre: book.genre,
                            cornerRadius: 6
                        )
                        .frame(width: 44, height: 66)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            
                            Text(book.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            HStack {
                                Text("\(book.pagesRead)/\(book.totalPages) стр.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if let r = book.rating {
                                    Text(r.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                } else {
                                    Text(book.status.rawValue)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(book.status.color)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        bookForProgressUpdate = book
                    } label: {
                        Label("Страницы", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        bookForPlan = book
                    } label: {
                        Label("В план", systemImage: "calendar.badge.plus")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }
}

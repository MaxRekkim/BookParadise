import SwiftUI
import UIKit

public struct LibraryView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @State private var bookForProgressUpdate: Book? = nil
    @State private var bookForPlan: Book? = nil
    @State private var librarySegment: Int = 0 // 0: Книги, 1: Серии и циклы
    @State private var isShowingAddBook: Bool = false
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Переключатель между каталогом книг и книжными циклами
                Picker("Категория", selection: $librarySegment) {
                    Text("Книги (\(viewModel.filteredBooks.count))").tag(0)
                    Text("Серии и циклы (\(viewModel.normalizedCycles.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 6)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                if librarySegment == 1 {
                    CyclesView(viewModel: viewModel, isEmbedded: true)
                } else {
                    // Строка быстрых фильтров-чипсов с фиксацией от вертикального люфта
                    filterChipsBar
                
                // Активные теги фильтров (если применены)
                if viewModel.filterCriteria.isActive {
                    activeFiltersBar
                }
                
                // Сортировка, кнопка фильтров и переключатель вида (Сетка / Список)
                HStack(spacing: 10) {
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
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                    }
                    
                    // Кнопка расширенных фильтров с бейджем активных
                    Button(action: {
                        viewModel.isFilterSheetPresented = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.filterCriteria.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            Text("Фильтры")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            if viewModel.filterCriteria.isActive {
                                Text("\(viewModel.filterCriteria.activeCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(theme.primaryAccent)
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(viewModel.filterCriteria.isActive ? theme.primaryAccent : .primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                    }
                    
                    Spacer()
                    
                    // Переключатель вида (Сетка / Список / Книжная полка)
                    HStack(spacing: 2) {
                        ForEach(LibraryLayoutMode.allCases) { mode in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.layoutMode = mode
                                    viewModel.isGridMode = (mode == .grid)
                                }
                            }) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(viewModel.layoutMode == mode ? .white : .secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(viewModel.layoutMode == mode ? theme.primaryAccent : Color.clear)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(2)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                
                // Контент: Сетка, Список или Книжная полка
                switch viewModel.layoutMode {
                case .grid:
                    booksGrid
                case .list:
                    booksList
                case .bookshelf:
                    bookshelfSpineView
                }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(librarySegment == 1 ? "Циклы (\(viewModel.normalizedCycles.count))" : "Библиотека (\(viewModel.filteredBooks.count))")
            .searchable(text: $viewModel.searchText, prompt: "Поиск по названию, автору, ISBN...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddBook = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primaryAccent)
                    }
                    .accessibilityLabel("Добавить книгу")
                }
            }
            .sheet(isPresented: $isShowingAddBook) {
                AddBookSheet(viewModel: viewModel)
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $viewModel.isFilterSheetPresented) {
                BookFilterSheet(viewModel: viewModel)
            }
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
    
    // MARK: - Чипсы быстрых фильтров (монолитные, строго горизонтальные)
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
                        .background(isSelected ? theme.primaryAccent : Color(UIColor.secondarySystemGroupedBackground))
                        .foregroundColor(isSelected ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(height: 44)
    }
    
    // MARK: - Активные фильтры-теги с крестиком для быстрого сброса
    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(viewModel.filterCriteria.genres), id: \.self) { g in
                    removableFilterTag(title: g.rawValue) {
                        viewModel.filterCriteria.genres.remove(g)
                    }
                }
                ForEach(Array(viewModel.filterCriteria.statuses), id: \.self) { s in
                    removableFilterTag(title: s.rawValue) {
                        viewModel.filterCriteria.statuses.remove(s)
                    }
                }
                ForEach(Array(viewModel.filterCriteria.formats), id: \.self) { f in
                    removableFilterTag(title: f.rawValue) {
                        viewModel.filterCriteria.formats.remove(f)
                    }
                }
                ForEach(Array(viewModel.filterCriteria.ratings), id: \.self) { r in
                    removableFilterTag(title: r.rawValue) {
                        viewModel.filterCriteria.ratings.remove(r)
                    }
                }
                if viewModel.filterCriteria.cycleMode != .all {
                    removableFilterTag(title: viewModel.filterCriteria.cycleMode.rawValue) {
                        viewModel.filterCriteria.cycleMode = .all
                    }
                }
                if viewModel.filterCriteria.pageRange != .all {
                    removableFilterTag(title: viewModel.filterCriteria.pageRange.rawValue) {
                        viewModel.filterCriteria.pageRange = .all
                    }
                }
                if viewModel.filterCriteria.onlyWithFiles {
                    removableFilterTag(title: "С файлом Kindle") {
                        viewModel.filterCriteria.onlyWithFiles = false
                    }
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.filterCriteria.reset()
                    }
                }) {
                    Text("Сбросить все ✕")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(height: 34)
    }
    
    private func removableFilterTag(title: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
        }
        .foregroundColor(theme.primaryAccent)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(theme.primaryAccent.opacity(0.12))
        .cornerRadius(8)
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
    
    // MARK: - Адаптивная книжная витрина (3 колонки на iPhone, 4-6 на iPad/Mac)
    private var booksGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 12)], spacing: 16) {
                ForEach(viewModel.filteredBooks) { book in
                    NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                        VStack(alignment: .leading, spacing: 10) {
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
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(book.typographicTitle)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text(book.typographicAuthor)
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(height: 44, alignment: .topLeading)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
            .padding(.top, 12)
            .padding(.bottom, 90)
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
                        .frame(width: 50, height: 75)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(book.typographicTitle)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .lineLimit(1)
                            
                            Text(book.typographicAuthor)
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

    // MARK: - 3. Виртуальная книжная полка с корешками
    private var bookshelfSpineView: some View {
        ScrollView {
            VStack(spacing: 24) {
                let books = viewModel.filteredBooks
                if books.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("На полке пока нет книг")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    let chunks = chunkBooks(books, size: 8)
                    ForEach(Array(chunks.enumerated()), id: \.offset) { index, shelfBooks in
                        VStack(spacing: 0) {
                            // Книги на полке с глубокой нишей и горизонтальной прокруткой
                            ZStack(alignment: .bottom) {
                                // Задняя дубовая стенка книжного шкафа с тенью от верхней полки
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.16, green: 0.12, blue: 0.09).opacity(0.85),
                                                Color(red: 0.22, green: 0.16, blue: 0.12).opacity(0.95)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        LinearGradient(
                                            colors: [Color.black.opacity(0.55), Color.clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                    .frame(height: 195)
                                    .padding(.horizontal, 8)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        ForEach(shelfBooks) { book in
                                            NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                                                BookSpineView(book: book)
                                            }
                                            .buttonStyle(.plain)
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
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 2)
                                }
                            }

                            // Деревянная полочная балка из натурального массива дуба
                            shelfBeam
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        }
    }

    private var shelfBeam: some View {
        VStack(spacing: 0) {
            // Верхний скос балки (световой блик)
            Rectangle()
                .fill(Color(red: 0.82, green: 0.64, blue: 0.46))
                .frame(height: 2)

            // Фронтальная балка массива дуба
            LinearGradient(
                colors: [
                    Color(red: 0.65, green: 0.46, blue: 0.30),
                    Color(red: 0.45, green: 0.28, blue: 0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 14)
            .overlay(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(red: 0.78, green: 0.68, blue: 0.42).opacity(0.4))
                        .frame(height: 0.8)
                }
            )
            .shadow(color: .black.opacity(0.35), radius: 4, y: 3)

            // Глубокая тень под полкой
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.28), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
        }
    }

    private func chunkBooks(_ books: [Book], size: Int) -> [[Book]] {
        var chunks: [[Book]] = []
        var current: [Book] = []
        for b in books {
            current.append(b)
            if current.count == size {
                chunks.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks
    }
}

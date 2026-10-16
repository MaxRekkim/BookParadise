import Foundation
import SwiftUI
import Combine

public enum StatusFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case inProgress = "Читаю"
    case unread = "В очереди"
    case read = "Прочитано"
    case paper = "Бумажные"
    case electronic = "Электронные"
    
    public var id: String { rawValue }
}

public enum SortOption: String, CaseIterable, Identifiable {
    case byNumber = "По номеру (#)"
    case byPurchaseDate = "По дате покупки"
    case byRating = "По оценке"
    case byPages = "По страницам"
    
    public var id: String { rawValue }
}

public enum CycleFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case completed = "Завершенные"
    case inProgress = "В процессе"
    case notStarted = "Не начатые"
    
    public var id: String { rawValue }
}

@MainActor
public class LibraryViewModel: ObservableObject {
    public static let shared = LibraryViewModel()
    
    @Published public var books: [Book] = []
    @Published public var bingoItems: [BingoItem] = []
    @Published public var stats: AppStats = AppStats()
    
    @Published public var isLoading: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var lastSyncDate: Date? = nil
    
    // UI Фильтры и поиск
    @Published public var searchText: String = ""
    @Published public var selectedStatusFilter: StatusFilter = .all
    @Published public var selectedGenreFilter: Genre? = nil
    @Published public var selectedEditionFilter: String? = nil
    @Published public var sortOption: SortOption = .byNumber
    @Published public var isGridMode: Bool = true
    
    // Расширенные фильтры
    @Published public var filterCriteria: BookFilterCriteria = BookFilterCriteria()
    @Published public var isFilterSheetPresented: Bool = false
    
    // Бинго и Планы
    @Published public var selectedBingoMonth: String = "ОКТЯБРЬ"
    
    // Циклы
    @Published public var cycleFilter: CycleFilter = .all
    
    // Лист активных авторов и изданий для автодополнения
    @Published public var availableAuthors: [String] = []
    @Published public var availableEditions: [String] = []
    
    public init() {
        loadInitialData()
    }
    
    // MARK: - Инициализация (Offline-First)
    public func loadInitialData() {
        if let stored = iCloudSyncManager.shared.load() {
            self.books = stored.books
            self.bingoItems = stored.bingo
        } else if let cached = GoogleSheetsAPIService.shared.loadFromLocalCache() {
            self.books = cached.books
            self.bingoItems = cached.bingo
            iCloudSyncManager.shared.save(books: self.books, bingo: self.bingoItems)
        } else {
            // Если кэша еще нет — загружаем эталонную базу
            self.books = SampleData.generateInitialBooks()
            self.bingoItems = SampleData.generateInitialBingo()
            persistData()
        }
        
        recalculateStats()
        updateMetadataLists()
        prefetchCovers()
        
        // Фоновая синхронизация, если настроен URL
        if GoogleSheetsAPIService.shared.isConfigured {
            Task {
                await syncWithCloud()
            }
        }
    }
    
    // MARK: - Двусторонняя синхронизация (GET)
    public func syncWithCloud() async {
        guard GoogleSheetsAPIService.shared.isConfigured else { return }
        
        isSyncing = true
        errorMessage = nil
        
        do {
            let result = try await GoogleSheetsAPIService.shared.fetchLibrary()
            if !result.books.isEmpty {
                self.books = result.books
            }
            if !result.bingo.isEmpty {
                self.bingoItems = result.bingo
            }
            if let serverStats = result.stats {
                self.stats = serverStats
            } else {
                recalculateStats()
            }
            updateMetadataLists()
            prefetchCovers()
            persistData()
            self.lastSyncDate = Date()
        } catch {
            self.errorMessage = error.localizedDescription
            print("Sync failed: \(error)")
        }
        
        isSyncing = false
    }
    
    // MARK: - Сценарий А: Обновление прогресса чтения (Optimistic UI)
    public func updateProgress(for book: Book, newPages: Int, rating: BookRating? = nil) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        
        var updated = books[index]
        let oldPages = updated.pagesRead
        let total = updated.totalPages
        let clampedPages = min(total, max(0, newPages))
        
        updated.pagesRead = clampedPages
        let calcPercent = total > 0 ? (Double(clampedPages) / Double(total)) * 100.0 : 0.0
        updated.progressPercent = round(calcPercent * 10) / 10
        
        let todayStr = formatDate(Date())
        let monthNum = Calendar.current.component(.month, from: Date())
        
        if clampedPages == 0 {
            updated.status = .notStarted
        } else if clampedPages < total {
            updated.status = .inProgress
            if updated.startDate == nil || oldPages == 0 {
                updated.startDate = todayStr
                updated.monthIndex = monthNum
            }
        } else {
            // Прочитано
            updated.status = .read
            if updated.startDate == nil {
                updated.startDate = todayStr
                updated.monthIndex = monthNum
            }
            updated.endDate = todayStr
            if let rating = rating {
                updated.rating = rating
            }
        }
        
        // Optimistic UI: мгновенно обновляем модель
        books[index] = updated
        
        // Пересчитываем процент серии, если книга входит в цикл
        if updated.hasCycle {
            recalculateCyclePercent(for: updated.cycleName)
        }
        
        recalculateStats()
        persistData()
        
        // Отправляем фоновый POST-запрос в таблицу
        GoogleSheetsAPIService.shared.postProgressUpdate(
            bookId: updated.id,
            pagesRead: clampedPages,
            rating: updated.rating
        )
    }

    public func updateBook(_ book: Book) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index] = book
        if book.hasCycle {
            recalculateCyclePercent(for: book.cycleName)
        }
        recalculateStats()
        persistData()
    }
    
    // MARK: - Сценарий Б: Добавление новой книги
    public func addNewBook(
        title: String,
        author: String,
        totalPages: Int,
        genre: Genre,
        edition: String = "",
        isbn: String = "",
        cycleName: String = "-",
        cycleNumber: String = "-",
        coverURL: String = "",
        format: BookFormat = .paper,
        planMonth: String? = nil,
        purchaseDate: String? = nil
    ) {
        let maxId = books.map { $0.id }.max() ?? 0
        let newId = maxId + 1
        let todayStr = formatDate(Date())
        
        let newBook = Book(
            id: newId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            edition: edition.trimmingCharacters(in: .whitespacesAndNewlines),
            isbn: isbn,
            cycleNumber: cycleNumber.isEmpty ? "-" : cycleNumber,
            genre: genre,
            pagesRead: 0,
            totalPages: totalPages,
            progressPercent: 0.0,
            status: .notStarted,
            shelf: (format == .electronic) ? .onlineReading : .onShelf,
            planMonth: planMonth,
            format: format,
            cycleName: cycleName.isEmpty ? "-" : cycleName,
            coverURL: coverURL.isEmpty ? nil : coverURL,
            purchaseDate: purchaseDate ?? todayStr
        )
        
        books.insert(newBook, at: 0)
        recalculateStats()
        updateMetadataLists()
        persistData()
        
        // Фоновый запрос в Google Таблицу
        GoogleSheetsAPIService.shared.postAddBook(book: newBook)
        
        // Если указан месяц для плана — добавляем также в бинго
        if let month = planMonth, !month.isEmpty {
            addToBingo(book: newBook, month: month, planDays: 4)
        }
    }
    
    // MARK: - Сценарий В: Добавление в план / Бинго
    public func addToBingo(book: Book, month: String, planDays: Int) {
        let cleanMonth = month.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 1. Обновляем саму книгу
        if let idx = books.firstIndex(where: { $0.id == book.id }) {
            books[idx].planMonth = cleanMonth
        }
        
        // 2. Добавляем или обновляем в списке бинго
        if let bingoIdx = bingoItems.firstIndex(where: { $0.id == book.id || $0.title == book.title }) {
            bingoItems[bingoIdx].planMonth = cleanMonth
            bingoItems[bingoIdx].planDays = planDays
            bingoItems[bingoIdx].plannedPagesPerDay = Double(book.totalPages / max(1, planDays))
        } else {
            let newItem = BingoItem(
                id: book.id,
                title: book.title,
                author: book.author,
                planMonth: cleanMonth,
                totalPages: book.totalPages,
                startDate: book.startDate,
                genre: book.genre.rawValue,
                planDays: planDays,
                plannedPagesPerDay: Double(book.totalPages / max(1, planDays))
            )
            bingoItems.append(newItem)
        }
        
        persistData()
        GoogleSheetsAPIService.shared.postUpdatePlan(bookId: book.id, month: cleanMonth, planDays: planDays)
    }
    
    public func updateBingoPlanDays(item: BingoItem, newDays: Int) {
        guard let idx = bingoItems.firstIndex(where: { $0.id == item.id }) else { return }
        let clamped = max(1, newDays)
        bingoItems[idx].planDays = clamped
        bingoItems[idx].plannedPagesPerDay = Double(bingoItems[idx].totalPages / clamped)
        
        persistData()
        GoogleSheetsAPIService.shared.postUpdatePlan(bookId: item.id, month: bingoItems[idx].planMonth, planDays: clamped)
    }
    
    // MARK: - Удаление книги из плана бинго
    public func removeFromBingo(item: BingoItem) {
        bingoItems.removeAll(where: { $0.id == item.id })
        if let idx = books.firstIndex(where: { $0.id == item.id }) {
            books[idx].planMonth = nil
        }
        persistData()
        GoogleSheetsAPIService.shared.postUpdatePlan(bookId: item.id, month: "", planDays: 0)
    }

    // MARK: - Обновление рецензии/отзыва к книге
    public func updateReview(bookId: Int, review: String) {
        if let idx = books.firstIndex(where: { $0.id == bookId }) {
            books[idx].review = review.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : review
            persistData()
        }
    }
    
    // MARK: - Отфильтрованные книги для вкладки «Библиотека»
    public var filteredBooks: [Book] {
        var list = books
        
        // 1. Поиск по тексту (название, автор, ISBN)
        if !searchText.isEmpty {
            let query = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.author.lowercased().contains(query) ||
                $0.isbn.contains(query)
            }
        }
        
        // 2. Статусный фильтр
        switch selectedStatusFilter {
        case .all:
            break
        case .inProgress:
            list = list.filter { $0.status == .inProgress }
        case .unread:
            list = list.filter { $0.status == .notStarted }
        case .read:
            list = list.filter { $0.status == .read }
        case .paper:
            list = list.filter { $0.format == .paper }
        case .electronic:
            list = list.filter { $0.format == .electronic }
        }
        
        // 3. Фильтр по жанру
        if let genre = selectedGenreFilter {
            list = list.filter { $0.genre == genre }
        }
        
        // 4. Фильтр по изданию
        if let edition = selectedEditionFilter {
            list = list.filter { $0.edition.contains(edition) }
        }

        // 5. Расширенные фильтры (FilterCriteria)
        if filterCriteria.isActive {
            if !filterCriteria.statuses.isEmpty {
                list = list.filter { filterCriteria.statuses.contains($0.status) }
            }
            if !filterCriteria.formats.isEmpty {
                list = list.filter { filterCriteria.formats.contains($0.format) }
            }
            if !filterCriteria.genres.isEmpty {
                list = list.filter { filterCriteria.genres.contains($0.genre) }
            }
            if !filterCriteria.ratings.isEmpty {
                list = list.filter { book in
                    guard let r = book.rating else { return false }
                    return filterCriteria.ratings.contains(r)
                }
            }
            if !filterCriteria.shelves.isEmpty {
                list = list.filter { filterCriteria.shelves.contains($0.shelf) }
            }
            switch filterCriteria.cycleMode {
            case .all: break
            case .onlyCycles:
                list = list.filter { $0.hasCycle }
            case .onlyStandalone:
                list = list.filter { !$0.hasCycle }
            }
            switch filterCriteria.pageRange {
            case .all: break
            case .short:
                list = list.filter { $0.totalPages <= 300 }
            case .medium:
                list = list.filter { $0.totalPages > 300 && $0.totalPages <= 600 }
            case .thick:
                list = list.filter { $0.totalPages > 600 }
            }
            if filterCriteria.onlyWithFiles {
                list = list.filter { EBookStorageManager.shared.hasFile(for: $0.id) }
            }
        }
        
        // 6. Сортировка
        switch sortOption {
        case .byNumber:
            list.sort { $0.id < $1.id }
        case .byPurchaseDate:
            list.sort { ($0.purchaseDate ?? "") > ($1.purchaseDate ?? "") }
        case .byRating:
            list.sort { ($0.rating?.numericScore ?? 0) > ($1.rating?.numericScore ?? 0) }
        case .byPages:
            list.sort { $0.totalPages > $1.totalPages }
        }
        
        return list
    }
    
    // Книги «Читаю сейчас» для главного экрана
    public var readingNowBooks: [Book] {
        return books.filter { $0.status == .inProgress }
    }
    
    // MARK: - Нормализация и группировка циклов
    public var normalizedCycles: [BookCycle] {
        var dict: [String: (canonical: String, books: [Book])] = [:]
        
        for book in books where book.hasCycle {
            let key = book.cycleName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if dict[key] == nil {
                dict[key] = (book.cycleName.trimmingCharacters(in: .whitespacesAndNewlines), [])
            }
            dict[key]?.books.append(book)
        }
        
        var cycles: [BookCycle] = []
        for (_, val) in dict {
            let sortedBooks = val.books.sorted {
                let num1 = Int($0.cycleNumber) ?? 999
                let num2 = Int($1.cycleNumber) ?? 999
                return num1 < num2
            }
            let readCount = sortedBooks.filter { $0.status == .read }.count
            let total = sortedBooks.count
            let percent = total > 0 ? (Double(readCount) / Double(total)) * 100.0 : 0.0
            
            let refs = sortedBooks.map {
                CycleBookReference(id: $0.id, title: $0.title, cycleNumber: $0.cycleNumber, isRead: $0.status == .read)
            }
            
            cycles.append(BookCycle(
                name: val.canonical,
                totalBooks: total,
                readBooks: readCount,
                completionPercent: round(percent * 10) / 10,
                bookList: refs
            ))
        }
        
        cycles.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        
        switch cycleFilter {
        case .all:
            return cycles
        case .completed:
            return cycles.filter { $0.isCompleted }
        case .inProgress:
            return cycles.filter { $0.isInProgress }
        case .notStarted:
            return cycles.filter { $0.isNotStarted }
        }
    }
    
    // MARK: - Бинго: Книги выбранного месяца
    public var bingoItemsForSelectedMonth: [BingoItem] {
        let norm = selectedBingoMonth.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return bingoItems.filter { $0.planMonth == norm }
    }
    
    public var availableBingoMonths: [String] {
        return ["ИЮНЬ", "ИЮЛЬ", "АВГУСТ", "СЕНТЯБРЬ", "ОКТЯБРЬ", "НОЯБРЬ", "ДЕКАБРЬ", "ЯНВАРЬ", "ФЕВРАЛЬ", "МАРТ", "АПРЕЛЬ", "МАЙ", "ЗАБРОШЕНО"]
    }
    
    // MARK: - Автодополнение авторов
    public func filterAuthors(matching query: String) -> [String] {
        if query.isEmpty { return Array(availableAuthors.prefix(10)) }
        let q = query.lowercased()
        return availableAuthors.filter { $0.lowercased().contains(q) }
    }
    
    // MARK: - Вспомогательные вычисления
    private func recalculateCyclePercent(for cycleName: String) {
        let norm = cycleName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cycleBooks = books.filter { $0.cycleName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == norm }
        guard !cycleBooks.isEmpty else { return }
        
        let readCount = cycleBooks.filter { $0.status == .read }.count
        let percent = round((Double(readCount) / Double(cycleBooks.count)) * 1000) / 10
        
        for (idx, b) in books.enumerated() where b.cycleName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == norm {
            books[idx].cycleStatus = percent
        }
    }
    
    public func recalculateStats() {
        var read = 0
        var inProg = 0
        var unread = 0
        var paper = 0
        var electronic = 0
        var totalPages = 0
        
        var genreMap: [String: GenreStatItem] = [:]
        for g in Genre.allCases {
            genreMap[g.rawValue] = GenreStatItem(total: 0, read: 0)
        }
        
        var ratings: [String: Int] = [:]
        var purchases: [String: Int] = [:]
        
        for b in books {
            totalPages += b.pagesRead
            
            switch b.status {
            case .read: read += 1
            case .inProgress: inProg += 1
            case .notStarted: unread += 1
            }
            
            if b.format == .electronic {
                electronic += 1
            } else {
                paper += 1
            }
            
            if let item = genreMap[b.genre.rawValue] {
                genreMap[b.genre.rawValue] = GenreStatItem(
                    total: item.total + 1,
                    read: item.read + (b.status == .read ? 1 : 0)
                )
            }
            
            if let r = b.rating {
                ratings[r.rawValue] = (ratings[r.rawValue] ?? 0) + 1
            }
            
            if let date = b.purchaseDate, date.count >= 7 {
                let ym = String(date.prefix(7))
                purchases[ym] = (purchases[ym] ?? 0) + 1
            }
        }
        
        let total = books.count
        let percent = total > 0 ? (Double(read) / Double(total)) * 100.0 : 0.0
        
        self.stats = AppStats(
            totalBooks: total,
            readBooks: read,
            inProgressBooks: inProg,
            unreadBooks: unread,
            paperBooks: paper,
            electronicBooks: electronic,
            totalPagesRead: totalPages,
            percentRead: round(percent * 10) / 10,
            genreCounts: genreMap,
            ratingCounts: ratings,
            monthlyPurchases: purchases
        )
        
        WidgetDataExporter.shared.export(books: books)
    }
    
    public func updateBookProgress(bookId: Int, pagesRead: Int) {
        if let book = books.first(where: { $0.id == bookId }) {
            updateProgress(for: book, newPages: pagesRead)
        }
    }
    
    private func updateMetadataLists() {
        var authorsSet = Set(SampleData.sampleAuthors)
        var editionsSet = Set(SampleData.sampleEditions)
        
        for b in books {
            if !b.author.isEmpty { authorsSet.insert(b.author) }
            if !b.edition.isEmpty {
                b.edition.components(separatedBy: ";").forEach {
                    let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { editionsSet.insert(trimmed) }
                }
            }
        }
        
        self.availableAuthors = Array(authorsSet).sorted()
        self.availableEditions = Array(editionsSet).sorted()
    }
    
    private func prefetchCovers() {
        let urls = books.compactMap { $0.cleanCoverURL }
        ImageCacheManager.shared.prefetch(urls: urls)
    }
    
    public func persistData() {
        iCloudSyncManager.shared.save(books: books, bingo: bingoItems)
        GoogleSheetsAPIService.shared.saveToLocalCache(books: books, bingo: bingoItems)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

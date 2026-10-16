import SwiftUI
import UIKit
import Charts

public struct DashboardView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var lendingManager = LendingManager.shared
    @State private var bookToUpdateProgress: Book? = nil
    @State private var bookForReadingSession: Book? = nil
    @State private var isShowingSettings: Bool = false
    @State private var isShowingDetailedStats: Bool = false
    @State private var isShowingQuotes: Bool = false
    @State private var isShowingLending: Bool = false
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 0. Мотивация дня и прогресс годовой цели
                    DailyMotivationBanner(viewModel: viewModel)
                        .padding(.horizontal)

                    // 0.5. Книги у друзей (если есть активные записи)
                    if !lendingManager.activeRecords.isEmpty {
                        lendingBanner
                            .padding(.horizontal)
                    }
                    
                    // 1. Блок «Читаю сейчас» (Горизонтальный свайп)
                    readingNowSection
                    
                    // 2. Календарь активности (Сетка ПН–ВСК на 2026 год)
                    ReadingCalendarView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // 3. Карточки общей сводки (Адаптивная сетка)
                    summaryGridSection
                        .padding(.horizontal)
                    
                    // 3.5. Переход к подробной аналитике
                    detailedStatsBanner
                        .padding(.horizontal)
                    
                    // 4. Графики аналитики (SwiftCharts)
                    analyticsChartsSection
                        .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Книжный Рай")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { isShowingQuotes = true }) {
                            Image(systemName: "quote.bubble.fill")
                                .foregroundColor(theme.primaryAccent)
                        }
                        
                        Button(action: { isShowingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(theme.primaryAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingQuotes) {
                NavigationStack {
                    QuotesGalleryView(viewModel: viewModel)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Готово") { isShowingQuotes = false }
                            }
                        }
                }
            }
            .sheet(item: $bookToUpdateProgress) { book in
                ProgressUpdateSheet(viewModel: viewModel, book: book)
            }
            .sheet(item: $bookForReadingSession) { book in
                ReadingSessionView(viewModel: viewModel, book: book)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingDetailedStats) {
                NavigationStack {
                    DetailedStatsView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $isShowingLending) {
                LendingListView()
            }
            .refreshable {
                await viewModel.syncWithCloud()
            }
        }
    }
    
    // MARK: - 0.5. Баннер книг у друзей
    private var lendingBanner: some View {
        Button(action: { isShowingLending = true }) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.primaryAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Книги у друзей: \(lendingManager.activeRecords.count)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    let overdue = lendingManager.overdueRecords.count
                    if overdue > 0 {
                        Text("⚠️ Просрочено к возврату: \(overdue)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else {
                        Text("Все книги под контролем")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.primaryAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1. Читаю сейчас
    private var readingNowSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Читаю сейчас")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("\(viewModel.readingNowBooks.count) книги")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if viewModel.readingNowBooks.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Сейчас нет читаемых книг")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Выберите книгу из Библиотеки и начните читать!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.readingNowBooks) { book in
                            readingNowCard(for: book)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func readingNowCard(for book: Book) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BookCoverView(
                    coverURL: book.cleanCoverURL,
                    title: book.title,
                    author: book.author,
                    genre: book.genre,
                    cornerRadius: 10
                )
                .frame(width: 85, height: 125)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.genre.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(book.genre.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(book.genre.accentColor.opacity(0.12))
                        .cornerRadius(6)
                    
                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Осталось: \(book.remainingPages) стр.")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Шкала прогресса
            VStack(spacing: 4) {
                HStack {
                    Text("\(book.pagesRead) из \(book.totalPages) стр.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(book.displayProgressString)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(height: 7)
                        
                        Capsule()
                            .fill(LinearGradient(colors: [theme.primaryAccent, theme.secondaryAccent], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(min(1.0, Double(book.pagesRead) / Double(max(1, book.totalPages)))), height: 7)
                    }
                }
                .frame(height: 7)
            }
            
            // Кнопки управления: Чтение с таймером и Быстрый ввод страниц
            HStack(spacing: 8) {
                Button(action: {
                    bookForReadingSession = book
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("Сессия")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(theme.primaryAccent)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    bookToUpdateProgress = book
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Страница")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(theme.primaryAccent.opacity(0.12))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 290)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 3. Сводка (Адаптивная 2x2 на iPhone, 4 в ряд на Mac)
    private var summaryGridSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 300), spacing: 12)], spacing: 12) {
            // 1. Все книги в библиотеке
            NavigationLink(destination: FilteredBooksView(
                title: "В библиотеке",
                books: viewModel.books,
                viewModel: viewModel
            )) {
                MetricCard(
                    title: "В библиотеке",
                    value: "\(viewModel.stats.totalBooks)",
                    subtitle: "\(viewModel.stats.paperBooks) бум. / \(viewModel.stats.electronicBooks) эл.",
                    icon: "books.vertical.fill",
                    color: .blue,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
            
            // 2. Прочитанные книги
            NavigationLink(destination: FilteredBooksView(
                title: "Прочитано",
                books: viewModel.books.filter { $0.status == .read },
                viewModel: viewModel
            )) {
                MetricCard(
                    title: "Прочитано",
                    value: "\(viewModel.stats.readBooks)",
                    subtitle: "\(String(format: "%.1f%%", viewModel.stats.percentRead)) библиотеки",
                    icon: "checkmark.seal.fill",
                    color: .green,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
            
            // 3. Книги в очереди
            NavigationLink(destination: FilteredBooksView(
                title: "В очереди",
                books: viewModel.books.filter { $0.status == .notStarted },
                viewModel: viewModel
            )) {
                MetricCard(
                    title: "В очереди",
                    value: "\(viewModel.stats.unreadBooks)",
                    subtitle: "Ждут своего часа",
                    icon: "clock.fill",
                    color: .orange,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
            
            // 4. Темп чтения и годовая цель
            NavigationLink(destination: ReadingChallengeView(viewModel: viewModel)) {
                MetricCard(
                    title: "Темп чтения",
                    value: "42 стр./дн.",
                    subtitle: "\(viewModel.stats.totalPagesRead) стр. всего",
                    icon: "bolt.fill",
                    color: .purple,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - 3.5. Баннер перехода к подробной аналитике
    private var detailedStatsBanner: some View {
        Button(action: { isShowingDetailedStats = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(theme.primaryAccent.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.primaryAccent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Подробная аналитика и статистика")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Text("Прогноз цели 2026, темп чтения, форматы и история сессий")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 4. Графики SwiftCharts
    private var analyticsChartsSection: some View {
        VStack(spacing: 16) {
            // Распределение по жанрам (Горизонтальный бар-чарт)
            VStack(alignment: .leading, spacing: 12) {
                Text("Распределение по жанрам")
                    .font(.headline)
                
                Chart {
                    ForEach(Genre.allCases) { genre in
                        let stat = viewModel.stats.genreCounts[genre.rawValue] ?? GenreStatItem(total: 0, read: 0)
                        
                        BarMark(
                            x: .value("Книг", stat.total),
                            y: .value("Жанр", genre.rawValue)
                        )
                        .foregroundStyle(genre.accentColor.opacity(0.35))
                        .position(by: .value("Тип", "На полке"))
                        
                        BarMark(
                            x: .value("Книг", stat.read),
                            y: .value("Жанр", genre.rawValue)
                        )
                        .foregroundStyle(genre.accentColor)
                        .position(by: .value("Тип", "Прочитано"))
                    }
                }
                .chartLegend(position: .top, alignment: .trailing)
                .frame(height: 260)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            
            // Распределение оценок
            VStack(alignment: .leading, spacing: 12) {
                Text("Статистика оценок")
                    .font(.headline)
                
                Chart {
                    ForEach(BookRating.allCases) { rating in
                        let count = viewModel.stats.ratingCounts[rating.rawValue] ?? 0
                        BarMark(
                            x: .value("Оценка", rating.rawValue),
                            y: .value("Количество", count)
                        )
                        .foregroundStyle(Color.orange.gradient)
                        .annotation(position: .top) {
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            
            // Динамика покупок по месяцам
            VStack(alignment: .leading, spacing: 12) {
                Text("Книжные покупки (по дате покупки)")
                    .font(.headline)
                
                let sortedPurchases = viewModel.stats.monthlyPurchases.sorted { $0.key < $1.key }
                if sortedPurchases.isEmpty {
                    Text("Нет данных о покупках")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(height: 100)
                } else {
                    Chart {
                        ForEach(sortedPurchases, id: \.key) { item in
                            BarMark(
                                x: .value("Месяц", formatMonthKey(item.key)),
                                y: .value("Куплено книг", item.value)
                            )
                            .foregroundStyle(Color.teal.gradient)
                        }
                    }
                    .frame(height: 180)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    private func formatMonthKey(_ key: String) -> String {
        let parts = key.split(separator: "-")
        if parts.count == 2, let year = parts.first, let monthNum = Int(parts[1]) {
            let months = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
            let mName = (monthNum >= 1 && monthNum <= 12) ? months[monthNum - 1] : String(parts[1])
            let shortYear = year.suffix(2)
            return "\(mName) '\(shortYear)"
        }
        return key
    }
}

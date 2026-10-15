import SwiftUI
import UIKit
import Charts

public struct DashboardView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @State private var bookToUpdateProgress: Book? = nil
    @State private var bookForReadingSession: Book? = nil
    @State private var isShowingSettings: Bool = false
    
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
                    
                    // 1. Блок «Читаю сейчас» (Горизонтальный свайп)
                    readingNowSection
                    
                    // 2. Календарь активности (Сетка ПН–ВСК на 2026 год)
                    ReadingCalendarView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // 3. Карточки общей сводки (Адаптивная сетка)
                    summaryGridSection
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
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(theme.primaryAccent)
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
            .refreshable {
                await viewModel.syncWithCloud()
            }
        }
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
            MetricCard(
                title: "В библиотеке",
                value: "\(viewModel.stats.totalBooks)",
                subtitle: "\(viewModel.stats.paperBooks) бум. / \(viewModel.stats.electronicBooks) эл.",
                icon: "books.vertical.fill",
                color: .blue
            )
            
            MetricCard(
                title: "Прочитано",
                value: "\(viewModel.stats.readBooks)",
                subtitle: "\(String(format: "%.1f%%", viewModel.stats.percentRead)) библиотеки",
                icon: "checkmark.seal.fill",
                color: .green
            )
            
            MetricCard(
                title: "В очереди",
                value: "\(viewModel.stats.unreadBooks)",
                subtitle: "Ждут своего часа",
                icon: "clock.fill",
                color: .orange
            )
            
            MetricCard(
                title: "Темп чтения",
                value: "42 стр./дн.",
                subtitle: "\(viewModel.stats.totalPagesRead) стр. всего",
                icon: "bolt.fill",
                color: .purple
            )
        }
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
            
            // Динамика покупок по месяцам (столбец W)
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
                                x: .value("Месяц", item.key),
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
}

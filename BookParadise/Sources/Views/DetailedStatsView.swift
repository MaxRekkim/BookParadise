import SwiftUI
import UIKit
import Charts

public struct DetailedStatsView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @AppStorage("annualGoalBooks") private var annualGoal: Int = 30
    @Environment(\.dismiss) private var dismiss
    public var onDismiss: (() -> Void)? = nil

    public init(viewModel: LibraryViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private func handleDismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
        #if canImport(UIKit)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .dismiss(animated: true, completion: nil)
        #endif
    }

    private var currentDayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    }

    private var daysInYear: Int {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        return isLeap ? 366 : 365
    }

    private var expectedBooksByNow: Double {
        let fractionOfYear = Double(currentDayOfYear) / Double(daysInYear)
        return fractionOfYear * Double(annualGoal)
    }

    private var goalDelta: Double {
        Double(viewModel.stats.readBooks) - expectedBooksByNow
    }

    private var averagePagesPerReadBook: Int {
        guard viewModel.stats.readBooks > 0 else { return 0 }
        return viewModel.stats.totalPagesRead / viewModel.stats.readBooks
    }

    private var totalSessionMinutes: Int {
        sessionManager.sessionHistory.reduce(0) { $0 + ($1.durationSeconds / 60) }
    }

    private var averageSessionSpeed: Double {
        let valid = sessionManager.sessionHistory.filter { $0.speedPagesPerHour > 0 }
        guard !valid.isEmpty else { return 0.0 }
        let sum = valid.reduce(0.0) { $0 + $1.speedPagesPerHour }
        return (sum / Double(valid.count)).rounded()
    }

    private var masterpieceBooks: [Book] {
        viewModel.books.filter { $0.rating == .masterpiece }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Группа 1: Базовая аналитика и годовой прогноз
                Group {
                    annualGoalForecastCard
                        .padding(.horizontal)
                        .padding(.top, 12)

                    velocityMetricsGrid
                        .padding(.horizontal)

                    ReadingHeatmapView()
                        .padding(.horizontal)

                    formatComparisonCard
                        .padding(.horizontal)

                    genreBreakdownCard
                        .padding(.horizontal)
                }

                // Группа 2: Когнитивные радары и экономика
                Group {
                    GenreRadarChartView(books: viewModel.books)
                        .padding(.horizontal)

                    TimeTravelAxisCardView(books: viewModel.books)
                        .padding(.horizontal)

                    LibraryEconomicsCardView(books: viewModel.books, sessions: sessionManager.sessionHistory)
                        .padding(.horizontal)

                    DNFAnalyticsCardView(books: viewModel.books)
                        .padding(.horizontal)
                }

                // Группа 3: Литературная Онтология (Wave 4)
                Group {
                    CharacterRelationshipGraphView()
                        .padding(.horizontal)

                    BookChronologyTimelineView()
                        .padding(.horizontal)

                    AuthorInfluenceMatrixView()
                        .padding(.horizontal)

                    QuoteSemanticClusterView()
                        .padding(.horizontal)

                    WorldbuildingLoreVaultView()
                        .padding(.horizontal)
                }

                // Группа 4: Системная интеграция iOS & macOS (Wave 5: v3.5.0)
                Group {
                    InteractiveReadingWidgetView()
                        .padding(.horizontal)

                    ReadingLiveActivityView()
                        .padding(.horizontal)

                    SpotlightSearchDebugView()
                        .padding(.horizontal)

                    AppIntentsConfigView()
                        .padding(.horizontal)

                    MenuBarCompanionView()
                        .padding(.horizontal)
                }

                // Группа 5: PKM и Универсальная синхронизация (Wave 6: v3.6.0)
                Group {
                    ObsidianVaultSyncView()
                        .padding(.horizontal)

                    UniversalLibraryImporterView()
                        .padding(.horizontal)

                    ReadingAlmanacPreviewView()
                        .padding(.horizontal)

                    ReadingChronotypeView()
                        .padding(.horizontal)
                }

                // Группа 6: The Sovereign Sanctuary 4.0 (Wave 7: v4.0.0)
                Group {
                    SanctuaryMasterOverviewView()
                        .padding(.horizontal)

                    SanctuaryAtmosphereConductorView()
                        .padding(.horizontal)

                    CognitiveFlowStateView()
                        .padding(.horizontal)

                    SovereignVaultSecurityView()
                        .padding(.horizontal)

                    LiteraryPantheonView()
                        .padding(.horizontal)
                }

                // Группа 7: Оценки и логи
                Group {
                    ratingsAndMasterpiecesCard
                        .padding(.horizontal)

                    sessionHistoryCard
                        .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Аналитика и статистика")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Готово") { handleDismiss() }
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryAccent)
                    .keyboardShortcut(.cancelAction)
            }
        }
        .onMacExitCommand {
            handleDismiss()
        }
        .interactiveDismissDisabled(false)
    }

    // MARK: - 1. Годовая цель и математический прогноз
    private var annualGoalForecastCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Цель 2026 года")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryAccent)
                        .textCase(.uppercase)

                    Text("\(viewModel.stats.readBooks) из \(annualGoal) книг")
                        .font(.title2)
                        .fontWeight(.heavy)
                }

                Spacer()

                let percent = annualGoal > 0 ? min(100.0, (Double(viewModel.stats.readBooks) / Double(annualGoal)) * 100.0) : 0.0
                Text(String(format: "%.1f%%", percent))
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundColor(theme.primaryAccent)
            }

            // Шкала прогресса с меткой ожидаемого графика
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 12)

                    // Фактический прогресс
                    let actualRatio = annualGoal > 0 ? min(1.0, Double(viewModel.stats.readBooks) / Double(annualGoal)) : 0.0
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryAccent, theme.secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(actualRatio), height: 12)

                    // Маркер расчетного графика на сегодняшний день
                    let expectedRatio = min(1.0, expectedBooksByNow / Double(max(1, annualGoal)))
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 3, height: 18)
                        .offset(x: max(0, min(geo.size.width - 3, geo.size.width * CGFloat(expectedRatio))))
                }
            }
            .frame(height: 18)

            // Прогноз и рекомендация
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: goalDelta >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(goalDelta >= 0 ? .green : .orange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    if goalDelta >= 0 {
                        let ahead = Int(goalDelta.rounded())
                        Text(ahead > 0 ? "Вы опережаете график на \(ahead) \(pluralBooks(ahead))!" : "Вы идете строго по запланированному графику!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        let forecastTotal = Int((Double(viewModel.stats.readBooks) / Double(currentDayOfYear) * Double(daysInYear)).rounded())
                        Text("При сохранении текущего темпа вы прочитаете около \(forecastTotal) книг к 31 декабря.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        let behind = abs(Int(goalDelta.rounded()))
                        Text("Отставание от графика: \(behind) \(pluralBooks(behind))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)

                        let remainingBooks = max(0, annualGoal - viewModel.stats.readBooks)
                        let remainingDays = max(1, daysInYear - currentDayOfYear)
                        let neededPagesPerDay = (remainingBooks * max(200, averagePagesPerReadBook)) / remainingDays
                        Text("Чтобы успеть закрыть цель в \(annualGoal) книг, читайте примерно \(neededPagesPerDay) стр./день (\(remainingDays) дн. осталось).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(UIColor.tertiarySystemFill).opacity(0.5))
            .cornerRadius(12)
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - 2. Сетка показателей скорости и объемов
    private var velocityMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 280), spacing: 12)], spacing: 12) {
            MetricCard(
                title: "Прочитано страниц",
                value: "\(viewModel.stats.totalPagesRead)",
                subtitle: "Всего зафиксировано",
                icon: "book.pages.fill",
                color: .blue
            )

            MetricCard(
                title: "Средний объем",
                value: "\(averagePagesPerReadBook) стр.",
                subtitle: "На одну книгу",
                icon: "doc.text.fill",
                color: .purple
            )

            MetricCard(
                title: "Время в сессиях",
                value: "\(totalSessionMinutes) мин",
                subtitle: "\(sessionManager.sessionHistory.count) сессий с таймером",
                icon: "stopwatch.fill",
                color: .teal
            )

            MetricCard(
                title: "Скорость чтения",
                value: averageSessionSpeed > 0 ? "\(Int(averageSessionSpeed)) стр./ч" : "42 стр./дн",
                subtitle: "Средний темп",
                icon: "bolt.fill",
                color: .orange
            )
        }
    }

    // MARK: - 3. Формат чтения: Бумажные vs Электронные
    private var formatComparisonCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Форматы чтения")
                .font(.headline)

            let total = max(1, viewModel.stats.totalBooks)
            let paperPercent = (Double(viewModel.stats.paperBooks) / Double(total)) * 100.0
            let elecPercent = (Double(viewModel.stats.electronicBooks) / Double(total)) * 100.0

            // Двухцветная полоса
            GeometryReader { geo in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.brown)
                        .frame(width: geo.size.width * CGFloat(paperPercent / 100.0))

                    Rectangle()
                        .fill(Color.indigo)
                        .frame(width: geo.size.width * CGFloat(elecPercent / 100.0))
                }
                .cornerRadius(6)
            }
            .frame(height: 14)

            HStack(spacing: 20) {
                // Бумажные
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.brown)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Бумажные")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.stats.paperBooks) книг (\(Int(paperPercent))%)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }

                Spacer()

                // Электронные
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.indigo)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Электронные")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.stats.electronicBooks) книг (\(Int(elecPercent))%)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - 4. Распределение по жанрам
    private var genreBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Аналитика жанров")
                    .font(.headline)
                Spacer()
                Text("9 жанров")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(Genre.allCases) { genre in
                    let stat = viewModel.stats.genreCounts[genre.rawValue] ?? GenreStatItem(total: 0, read: 0)
                    let percent = stat.total > 0 ? (Double(stat.read) / Double(stat.total)) * 100.0 : 0.0

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: genre.iconName)
                                .font(.caption)
                                .foregroundColor(genre.accentColor)
                                .frame(width: 20)

                            Text(genre.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            Spacer()

                            Text("\(stat.read) из \(stat.total) прочит.")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(String(format: "%.0f%%", percent))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(genre.accentColor)
                                .frame(width: 36, alignment: .trailing)
                        }

                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(UIColor.tertiarySystemFill))
                                    .frame(height: 5)

                                Capsule()
                                    .fill(genre.accentColor)
                                    .frame(width: g.size.width * CGFloat(min(1.0, percent / 100.0)), height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                }
            }
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - 5. Оценки и галерея Шедевров
    private var ratingsAndMasterpiecesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Шедевры и высшие оценки")
                .font(.headline)

            if masterpieceBooks.isEmpty {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    Text("Пока ни одной книге не присвоена оценка «Шедевр!». Вы можете отметить прочитанную книгу высшей оценкой.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(UIColor.tertiarySystemFill).opacity(0.4))
                .cornerRadius(10)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Золотая полка («Шедевр!» — \(masterpieceBooks.count) \(pluralBooks(masterpieceBooks.count))):")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(masterpieceBooks) { book in
                                NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        BookCoverView(
                                            coverURL: book.cleanCoverURL,
                                            title: book.title,
                                            author: book.author,
                                            genre: book.genre,
                                            cornerRadius: 8
                                        )
                                        .frame(width: 90, height: 135)

                                        Text(book.title)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .frame(width: 90, alignment: .leading)

                                        Text(book.author)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .frame(width: 90, alignment: .leading)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            Divider()

            // Интерактивный список оценок: клик открывает книги с этой оценкой
            VStack(alignment: .leading, spacing: 10) {
                Text("Книги по оценкам (нажмите для просмотра):")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(BookRating.allCases.reversed()) { rating in
                    let booksWithRating = viewModel.books.filter { $0.rating == rating }
                    if !booksWithRating.isEmpty {
                        NavigationLink(destination: FilteredBooksView(title: "Оценка: \(rating.rawValue)", books: booksWithRating, viewModel: viewModel)) {
                            HStack {
                                Text(rating.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                    .frame(minWidth: 80, alignment: .leading)

                                Spacer()

                                Text("\(booksWithRating.count) \(pluralBooks(booksWithRating.count))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }


    // MARK: - 6. История сессий чтения
    private var sessionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("История сессий чтения")
                    .font(.headline)
                Spacer()
                Text("\(sessionManager.sessionHistory.count) сессий")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if sessionManager.sessionHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("История сессий пока пуста")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Используйте таймер чтения «Сессия» на Дашборде или в деталях книги, чтобы автоматически фиксировать темп.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(sessionManager.sessionHistory.suffix(8).reversed()) { item in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(theme.primaryAccent.opacity(0.15))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: "book.pages")
                                        .font(.caption)
                                        .foregroundColor(theme.primaryAccent)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.bookTitle)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                Text("\(formatSessionDate(item.date)) • \(item.durationSeconds / 60) мин")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("+\(item.pagesRead) стр.")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)

                                if item.speedPagesPerHour > 0 {
                                    Text("\(Int(item.speedPagesPerHour)) стр./ч")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)

                        if item.id != sessionManager.sessionHistory.suffix(8).first?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }

    private func pluralBooks(_ count: Int) -> String {
        let rem10 = count % 10
        let rem100 = count % 100
        if rem100 >= 11 && rem100 <= 19 { return "книг" }
        if rem10 == 1 { return "книга" }
        if rem10 >= 2 && rem10 <= 4 { return "книги" }
        return "книг"
    }
}

// MARK: - Экран отфильтрованных книг по статусу или оценке
public struct FilteredBooksView: View {
    public let title: String
    public let books: [Book]
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    public var onDismiss: (() -> Void)? = nil
    @State private var searchText: String = ""

    public init(title: String, books: [Book], viewModel: LibraryViewModel, onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.books = books
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var displayedBooks: [Book] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return books
        } else {
            return books.filter {
                $0.title.lowercased().contains(trimmed) ||
                $0.author.lowercased().contains(trimmed) ||
                $0.genre.rawValue.lowercased().contains(trimmed)
            }
        }
    }

    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Поиск среди \(books.count) книг...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchBarView

            ScrollView {
                if displayedBooks.isEmpty {
                    VStack(spacing: 12) {
                        Spacer(minLength: 60)
                        Image(systemName: "books.vertical")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Книг не найдено")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 160), spacing: 12)], spacing: 16) {
                        ForEach(displayedBooks) { book in
                            NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    BookCoverView(
                                        coverURL: book.cleanCoverURL,
                                        title: book.title,
                                        author: book.author,
                                        genre: book.genre,
                                        cornerRadius: 8
                                    )
                                    .frame(height: 150)

                                    Text(book.title)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(UIColor.label))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(height: 32, alignment: .topLeading)

                                    Text(book.author)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .frame(alignment: .leading)
                                }
                            }
                            .buttonStyle(.plain)
                            .desktopHover(scale: 1.04, yOffset: -2)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 90)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("\(title) (\(books.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onDismiss = onDismiss {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onDismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryAccent)
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .onMacExitCommand {
            onDismiss?()
        }
        .interactiveDismissDisabled(false)
    }
}


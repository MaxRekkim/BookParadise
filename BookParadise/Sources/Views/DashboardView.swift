import SwiftUI
import UIKit
import Charts

public struct DashboardView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var achievementManager = AchievementManager.shared
    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @State private var bookToUpdateProgress: Book? = nil
    @State private var bookForReadingSession: Book? = nil
    @State private var isShowingSettings: Bool = false
    @State private var isShowingDetailedStats: Bool = false
    @State private var isShowingQuotes: Bool = false
    @State private var isShowingAchievements: Bool = false
    @State private var isShowingOracle: Bool = false
    @State private var isShowingWrapped: Bool = false
    @State private var isShowingAddBook: Bool = false
    @State private var isShowingNotesJournal: Bool = false
    @State private var isShowingSearchSheet: Bool = false
    @State private var isShowingSoundscapeMixer: Bool = false
    @ObservedObject private var updateManager = UpdateManager.shared
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 0. Баннер обновления ПО «по воздуху» (OTA)
                        if updateManager.isUpdateAvailable {
                            otaUpdateBanner
                                .padding(.horizontal)
                        }

                        // 0.1. RPG Уровни читателя и Стрики (v3.0)
                        RPGDashboardCard()
                            .padding(.horizontal)

                        // 0.2. Мотивация дня и прогресс годовой цели
                        DailyMotivationBanner(viewModel: viewModel)
                            .padding(.horizontal)

                        // 0.7. Капсула Времени (Литературные воспоминания)
                        TimeCapsuleCard(viewModel: viewModel) { book in
                            bookForReadingSession = book
                        }
                        .padding(.horizontal)
                        
                        // 0.8. Книжный Оракул-Сомелье (Карточка подсказки)
                        oracleQuickBanner
                            .padding(.horizontal)
                        
                        // 1. Блок «Книги в фокусе (Hot Reads)»
                        if !viewModel.readingNowBooks.isEmpty {
                            HotReadsBentoView(viewModel: viewModel, selectedBookForSession: $bookForReadingSession)
                            
                            // 1.2. Умный расчёт времени и темп чтения
                            if let activeBook = viewModel.readingNowBooks.first {
                                PaceVelocityCard(book: activeBook, sessions: sessionManager.sessionHistory)
                                    .padding(.horizontal)
                            }
                        } else {
                            readingNowSection
                        }
                        
                        // 1.5. Темпоритм чтения (Reading Velocity Spline Chart)
                        ReadingVelocityChartView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // 1.8. Кольцо годовой цели и Спектр библиотеки
                        ExecutiveQuotaRingAndMixView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // 2. Календарь активности (Сетка ПН–ВСК на 2026 год)
                        ReadingCalendarView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // 3. Карточки общей сводки (Адаптивная сетка)
                        summaryGridSection
                            .padding(.horizontal)
                        
                        // 3.5. Переход к подробной аналитике
                        detailedStatsBanner
                            .padding(.horizontal)

                        // 3.6. Reading Wrapped (Книжные итоги)
                        wrappedQuickBanner
                            .padding(.horizontal)
                        
                        // 3.7. Книжный Клуб и Синхронизация заметок (Wave 3)
                        ReadingClubCardView()
                            .padding(.horizontal)

                        // 3.8. Трекер аренды и возврата книг у друзей (Wave 3)
                        BookLendingTrackerView()
                            .padding(.horizontal)
                        
                        // 4. Графики аналитики (SwiftCharts)
                        analyticsChartsSection
                            .padding(.horizontal)
                        
                        Spacer(minLength: 90)
                    }
                    .padding(.top, 8)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Книжный Рай")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { isShowingOracle = true }) {
                            Image(systemName: "sparkles")
                                .foregroundColor(theme.primaryAccent)
                        }

                        Button(action: { isShowingAchievements = true }) {
                            HStack(spacing: 3) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                if achievementManager.unlockedCount > 0 {
                                    Text("\(achievementManager.unlockedCount)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }

                        Button(action: { isShowingNotesJournal = true }) {
                            Image(systemName: "note.text")
                                .foregroundColor(theme.primaryAccent)
                        }

                        Button(action: { isShowingQuotes = true }) {
                            Image(systemName: "quote.bubble.fill")
                                .foregroundColor(theme.primaryAccent)
                        }
                        
                        Button(action: {
                            isShowingSoundscapeMixer = true
                            HapticManager.shared.lightTap()
                        }) {
                            Image(systemName: SoundscapeManager.shared.isPlaying ? "waveform" : "headphones")
                                .foregroundColor(SoundscapeManager.shared.isPlaying ? theme.primaryAccent : .secondary)
                        }

                        Button(action: { isShowingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(theme.primaryAccent)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingNotesJournal) {
                NotesJournalView(viewModel: viewModel, onDismiss: {
                    isShowingNotesJournal = false
                })
                .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingOracle) {
                BookOracleView(viewModel: viewModel, onDismiss: {
                    isShowingOracle = false
                }) { book in
                    bookForReadingSession = book
                }
                .macSheetFrame()
            }
            .sheet(isPresented: $isShowingWrapped) {
                ReadingWrappedView(viewModel: viewModel, onDismiss: {
                    isShowingWrapped = false
                })
                .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingAchievements) {
                AchievementsView(onDismiss: {
                    isShowingAchievements = false
                })
                .macSheetFrame()
            }
            .sheet(isPresented: $isShowingQuotes) {
                QuotesGalleryView(viewModel: viewModel, onDismiss: {
                    isShowingQuotes = false
                })
                .macSheetFrame(large: true)
            }
            .sheet(item: $bookToUpdateProgress) { book in
                ProgressUpdateSheet(viewModel: viewModel, book: book, onDismiss: {
                    bookToUpdateProgress = nil
                })
                .macSheetFrame()
            }
            .sheet(item: $bookForReadingSession) { book in
                ReadingSessionView(viewModel: viewModel, book: book)
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingAddBook) {
                AddBookSheet(viewModel: viewModel)
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(viewModel: viewModel, onDismiss: {
                    isShowingSettings = false
                })
                .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingDetailedStats) {
                NavigationStack {
                    DetailedStatsView(viewModel: viewModel, onDismiss: {
                        isShowingDetailedStats = false
                    })
                }
                .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingSearchSheet) {
                NavigationStack {
                    FilteredBooksView(
                        title: "Поиск по библиотеке",
                        books: viewModel.books,
                        viewModel: viewModel,
                        onDismiss: { isShowingSearchSheet = false }
                    )
                }
                .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingSoundscapeMixer) {
                SoundscapeMixerSheet()
                    .macSheetFrame()
            }
            .onAppear {
                RPGLevelManager.shared.syncWithLibrary(
                    books: viewModel.books,
                    sessionsCount: sessionManager.sessionHistory.count,
                    quotesCount: QuotesManager.shared.quotes.count
                )
                StreakManager.shared.checkStreakIntegrity()
            }
            .refreshable {
                await viewModel.syncWithCloud()
            }
            .task {
                await updateManager.checkForUpdates(silent: true)
            }
        }
    }

    // MARK: - Баннер доступного обновления ПО «по воздуху» (OTA)
    private var otaUpdateBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primaryAccent.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "bolt.fill")
                    .foregroundColor(theme.primaryAccent)
                    .font(.system(size: 17, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Обновление v\(updateManager.latestVersion)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    Text("OTA")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(theme.primaryAccent)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                Text(updateManager.releaseTitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                Button(action: {
                    updateManager.installOTAUpdate()
                }) {
                    Label("Установить через OTA", systemImage: "bolt.fill")
                }
                
                Button(action: {
                    updateManager.installViaTrollStore()
                }) {
                    Label("Установить через TrollStore", systemImage: "sparkles")
                }
                
                if let ipa = updateManager.ipaURL {
                    Link(destination: ipa) {
                        Label("Скачать .IPA файл", systemImage: "arrow.down.doc.fill")
                    }
                }
                
                if let page = updateManager.releasePageURL {
                    Link(destination: page) {
                        Label("Открыть на GitHub", systemImage: "safari.fill")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 11))
                    Text("Обновить")
                        .font(.system(size: 11, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(theme.primaryAccent)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.primaryAccent.opacity(0.25), lineWidth: 1)
        )
        .desktopHover(scale: 1.01, yOffset: -1)
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
                        Text("Осталось: \(book.remainingPages) стр. • \(sessionManager.estimatedTimeToFinish(remainingPages: book.remainingPages).displayString)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
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

    // MARK: - 0.8. Карточка Оракула-Сомелье
    private var oracleQuickBanner: some View {
        Button(action: { isShowingOracle = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), theme.primaryAccent.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Книжный Оракул-Сомелье")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor.label))
                        Text("NEW")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple)
                            .cornerRadius(4)
                    }
                    Text("Не знаете, что читать? Подбор по настроению и времени")
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

    // MARK: - 3.6. Карточка Reading Wrapped
    private var wrappedQuickBanner: some View {
        Button(action: { isShowingWrapped = true }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.2), .pink.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Reading Wrapped • Книжные итоги")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Text("Высота книжной башни, темпоритм и открытка для соцсетей")
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

import SwiftUI

public enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard = 0
    case library = 1
    case bingo = 2
    case cycles = 3
    case quotes = 4
    case settings = 5
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .dashboard: return "Дашборд"
        case .library: return "Библиотека"
        case .bingo: return "Планы и Бинго"
        case .cycles: return "Книжные циклы"
        case .quotes: return "Цитаты и заметки"
        case .settings: return "Настройки"
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .library: return "books.vertical.fill"
        case .bingo: return "calendar.badge.clock"
        case .cycles: return "bookmark.circle.fill"
        case .quotes: return "quote.opening"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainTabView: View {
    @StateObject private var viewModel = LibraryViewModel.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var quotesManager = QuotesManager.shared
    
    @State private var selectedTab: AppTab = .dashboard
    
    // Модальные окна
    @State private var isShowingAddBook: Bool = false
    @State private var isShowingQuickPageSelector: Bool = false
    @State private var quickActionSheetPresented: Bool = false
    @State private var isShowingSessionPicker: Bool = false
    @State private var isShowingQuotePicker: Bool = false
    
    public init() {}
    
    public var body: some View {
        #if targetEnvironment(macCatalyst) || os(macOS)
        macOSLayout
            .commonModifiers(
                viewModel: viewModel,
                theme: theme,
                isShowingAddBook: $isShowingAddBook,
                isShowingQuickPageSelector: $isShowingQuickPageSelector,
                quickActionSheetPresented: $quickActionSheetPresented,
                isShowingSessionPicker: $isShowingSessionPicker,
                isShowingQuotePicker: $isShowingQuotePicker
            )
        #else
        iOSLayout
            .commonModifiers(
                viewModel: viewModel,
                theme: theme,
                isShowingAddBook: $isShowingAddBook,
                isShowingQuickPageSelector: $isShowingQuickPageSelector,
                quickActionSheetPresented: $quickActionSheetPresented,
                isShowingSessionPicker: $isShowingSessionPicker,
                isShowingQuotePicker: $isShowingQuotePicker
            )
        #endif
    }
    
    // MARK: - 1. НАСТОЛЬНЫЙ ИНТЕРФЕЙС ДЛЯ MACOS (САЙДБАР + ТУЛБАР)
    #if targetEnvironment(macCatalyst) || os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section(header: Text("Книжный Рай")) {
                    NavigationLink(value: AppTab.dashboard) {
                        Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
                    }
                    
                    NavigationLink(value: AppTab.library) {
                        HStack {
                            Label(AppTab.library.title, systemImage: AppTab.library.icon)
                            Spacer()
                            Text("\(viewModel.books.count)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                    
                    NavigationLink(value: AppTab.bingo) {
                        Label(AppTab.bingo.title, systemImage: AppTab.bingo.icon)
                    }
                    
                    NavigationLink(value: AppTab.cycles) {
                        HStack {
                            Label(AppTab.cycles.title, systemImage: AppTab.cycles.icon)
                            Spacer()
                            Text("\(viewModel.normalizedCycles.count)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                }
                
                Section(header: Text("Инструменты")) {
                    NavigationLink(value: AppTab.quotes) {
                        HStack {
                            Label(AppTab.quotes.title, systemImage: AppTab.quotes.icon)
                            Spacer()
                            if !quotesManager.quotes.isEmpty {
                                Text("\(quotesManager.quotes.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.primaryAccent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.primaryAccent.opacity(0.12))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    NavigationLink(value: AppTab.settings) {
                        Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Книжный Рай")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { isShowingAddBook = true }) {
                        Label("Новая книга", systemImage: "plus")
                    }
                    .keyboardShortcut("n", modifiers: .command)
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        Task { await viewModel.syncWithCloud() }
                    }) {
                        Label("Синхронизация", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
        } detail: {
            contentForSelectedTab
        }
    }
    #endif
    
    // MARK: - 2. МОБИЛЬНЫЙ ИНТЕРФЕЙС ДЛЯ IPHONE / IPAD (ТАББАР)
    private var iOSLayout: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(viewModel: viewModel)
                    .tag(AppTab.dashboard)
                
                LibraryView(viewModel: viewModel)
                    .tag(AppTab.library)
                
                BingoView(viewModel: viewModel)
                    .tag(AppTab.bingo)
                
                CyclesView(viewModel: viewModel)
                    .tag(AppTab.cycles)
                
                QuotesGalleryView(viewModel: viewModel)
                    .tag(AppTab.quotes)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }
            
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView(viewModel: viewModel)
        case .library:
            LibraryView(viewModel: viewModel)
        case .bingo:
            BingoView(viewModel: viewModel)
        case .cycles:
            CyclesView(viewModel: viewModel)
        case .quotes:
            QuotesGalleryView(viewModel: viewModel)
        case .settings:
            SettingsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Нижний мобильный таббар с кнопкой +
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .dashboard)
            tabButton(tab: .library)
            
            Button(action: {
                quickActionSheetPresented = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryAccent, theme.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: theme.primaryAccent.opacity(0.35), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -14)
            .padding(.horizontal, 6)
            
            tabButton(tab: .bingo)
            tabButton(tab: .cycles)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .background(
            Color(UIColor.secondarySystemGroupedBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func tabButton(tab: AppTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tab ? theme.primaryAccent : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Модификаторы для общих листов и экшенов
private extension View {
    func commonModifiers(
        viewModel: LibraryViewModel,
        theme: ThemeManager,
        isShowingAddBook: Binding<Bool>,
        isShowingQuickPageSelector: Binding<Bool>,
        quickActionSheetPresented: Binding<Bool>,
        isShowingSessionPicker: Binding<Bool>,
        isShowingQuotePicker: Binding<Bool>
    ) -> some View {
        self
            .confirmationDialog("Быстрое действие", isPresented: quickActionSheetPresented, titleVisibility: .visible) {
                Button("Добавить новую книгу") {
                    isShowingAddBook.wrappedValue = true
                }
                Button("Начать сессию чтения (Таймер)") {
                    isShowingSessionPicker.wrappedValue = true
                }
                Button("Сфотографировать / Добавить цитату") {
                    isShowingQuotePicker.wrappedValue = true
                }
                Button("Обновить прогресс чтения") {
                    isShowingQuickPageSelector.wrappedValue = true
                }
                Button("Отмена", role: .cancel) {}
            }
            .sheet(isPresented: isShowingAddBook) {
                AddBookSheet(viewModel: viewModel)
            }
            .sheet(isPresented: isShowingQuickPageSelector) {
                QuickBookPickerSheet(viewModel: viewModel, mode: .updateProgress)
            }
            .sheet(isPresented: isShowingSessionPicker) {
                QuickBookPickerSheet(viewModel: viewModel, mode: .readingSession)
            }
            .sheet(isPresented: isShowingQuotePicker) {
                QuickBookPickerSheet(viewModel: viewModel, mode: .quoteScanner)
            }
    }
}

// Быстрый выбор книги для действий
enum QuickPickerMode {
    case updateProgress
    case readingSession
    case quoteScanner
}

struct QuickBookPickerSheet: View {
    @ObservedObject var viewModel: LibraryViewModel
    var mode: QuickPickerMode = .updateProgress
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedBookForUpdate: Book? = nil
    @State private var selectedBookForSession: Book? = nil
    @State private var selectedBookForQuote: Book? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Читаю сейчас")) {
                    ForEach(viewModel.readingNowBooks) { book in
                        Button(action: { handleSelection(book) }) {
                            bookRow(book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section(header: Text("Все книги")) {
                    ForEach(viewModel.books.prefix(50)) { book in
                        Button(action: { handleSelection(book) }) {
                            HStack {
                                Text(book.title)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(book.pagesRead)/\(book.totalPages)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(titleForMode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .sheet(item: $selectedBookForUpdate) { book in
                ProgressUpdateSheet(viewModel: viewModel, book: book)
            }
            .sheet(item: $selectedBookForSession) { book in
                ReadingSessionView(viewModel: viewModel, book: book)
            }
            .sheet(item: $selectedBookForQuote) { book in
                QuoteScannerView(book: book)
            }
        }
    }
    
    private var titleForMode: String {
        switch mode {
        case .updateProgress: return "Обновить прогресс"
        case .readingSession: return "Начать чтение"
        case .quoteScanner: return "Добавить цитату"
        }
    }
    
    private func handleSelection(_ book: Book) {
        switch mode {
        case .updateProgress:
            selectedBookForUpdate = book
        case .readingSession:
            selectedBookForSession = book
        case .quoteScanner:
            selectedBookForQuote = book
        }
    }
    
    private func bookRow(_ book: Book) -> some View {
        HStack {
            BookCoverView(
                coverURL: book.cleanCoverURL,
                title: book.title,
                author: book.author,
                cornerRadius: 6
            )
            .frame(width: 36, height: 54)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("\(book.pagesRead) из \(book.totalPages) стр.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

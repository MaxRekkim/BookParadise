import SwiftUI

public enum AppTab: Int, CaseIterable {
    case dashboard = 0
    case library = 1
    case bingo = 2
    case cycles = 3
    
    public var title: String {
        switch self {
        case .dashboard: return "Дашборд"
        case .library: return "Библиотека"
        case .bingo: return "Планы"
        case .cycles: return "Циклы"
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .library: return "books.vertical.fill"
        case .bingo: return "calendar.badge.clock"
        case .cycles: return "bookmark.circle.fill"
        }
    }
}

public struct MainTabView: View {
    @StateObject private var viewModel = LibraryViewModel.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var selectedTab: AppTab = .dashboard
    
    // Модальные окна
    @State private var isShowingAddBook: Bool = false
    @State private var isShowingQuickPageSelector: Bool = false
    @State private var quickActionSheetPresented: Bool = false
    @State private var bookForReadingSession: Book? = nil
    @State private var bookForQuoteScanner: Book? = nil
    @State private var isShowingSessionPicker: Bool = false
    @State private var isShowingQuotePicker: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Контент активной вкладки
            TabView(selection: $selectedTab) {
                DashboardView(viewModel: viewModel)
                    .tag(AppTab.dashboard)
                
                LibraryView(viewModel: viewModel)
                    .tag(AppTab.library)
                
                BingoView(viewModel: viewModel)
                    .tag(AppTab.bingo)
                
                CyclesView(viewModel: viewModel)
                    .tag(AppTab.cycles)
            }
            .safeAreaInset(edge: .bottom) {
                // Отступ для кастомного таббара
                Color.clear.frame(height: 60)
            }
            
            // Кастомный нижний таббар с центральной кнопкой `+`
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .confirmationDialog("Быстрое действие", isPresented: $quickActionSheetPresented, titleVisibility: .visible) {
            Button("Добавить новую книгу") {
                isShowingAddBook = true
            }
            Button("Начать сессию чтения (Таймер)") {
                isShowingSessionPicker = true
            }
            Button("Сфотографировать / Добавить цитату") {
                isShowingQuotePicker = true
            }
            Button("Обновить прогресс чтения") {
                isShowingQuickPageSelector = true
            }
            Button("Отмена", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingAddBook) {
            AddBookSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingQuickPageSelector) {
            QuickBookPickerSheet(viewModel: viewModel, mode: .updateProgress)
        }
        .sheet(isPresented: $isShowingSessionPicker) {
            QuickBookPickerSheet(viewModel: viewModel, mode: .readingSession)
        }
        .sheet(isPresented: $isShowingQuotePicker) {
            QuickBookPickerSheet(viewModel: viewModel, mode: .quoteScanner)
        }
    }
    
    // MARK: - Кастомный TabBar с центральной плавающей кнопкой +
    private var customTabBar: some View {
        HStack(spacing: 0) {
            // Вкладка 1: Дашборд
            tabButton(tab: .dashboard)
            
            // Вкладка 2: Библиотека
            tabButton(tab: .library)
            
            // Центральная кнопка +
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
            .padding(.horizontal, 8)
            
            // Вкладка 3: Планы
            tabButton(tab: .bingo)
            
            // Вкладка 4: Циклы
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
        }
    }
}

// Быстрый выбор книги для действий из плавающей кнопки `+`
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
                            }
                        }
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
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

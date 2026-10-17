import SwiftUI
import UIKit

public enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard = 0
    case library = 1
    case journal = 2
    case stats = 3
    case sanctuary = 4
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .dashboard: return "Дашборд"
        case .library: return "Библиотека"
        case .journal: return "Хроника"
        case .stats: return "Аналитика"
        case .sanctuary: return "Кабинет"
        }
    }
    
    public var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .library: return "books.vertical.fill"
        case .journal: return "quote.opening"
        case .stats: return "chart.line.uptrend.xyaxis"
        case .sanctuary: return "books.vertical.circle.fill"
        }
    }
}

public struct MainTabView: View {
    @StateObject private var viewModel = LibraryViewModel.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var quotesManager = QuotesManager.shared
    
    @State private var selectedTab: AppTab = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // Модальные окна
    @State private var isShowingAddBook: Bool = false
    @State private var isShowingQuickPageSelector: Bool = false
    @State private var quickActionSheetPresented: Bool = false
    @State private var isShowingSessionPicker: Bool = false
    @State private var isShowingQuotePicker: Bool = false
    
    public init() {}
    
    public var body: some View {
        iOSLayout
        .confirmationDialog("Быстрое действие", isPresented: $quickActionSheetPresented, titleVisibility: .visible) {
            Button("Добавить новую книгу") {
                isShowingAddBook = true
            }
            Button("Начать сессию чтения (Секундомер)") {
                isShowingSessionPicker = true
            }
            Button("Сфотографировать / Добавить цитату") {
                isShowingQuotePicker = true
            }
            Button("Обновить прогресс чтения") {
                isShowingQuickPageSelector = true
            }
            Button("Хроника (Цитаты и заметки)") {
                selectedTab = .journal
            }
            Button("Книжные циклы и серии") {
                selectedTab = .library
            }
            Button("Отмена", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingAddBook) {
            AddBookSheet(viewModel: viewModel)
                .macSheetFrame(large: true)
        }
        .sheet(isPresented: $isShowingQuickPageSelector) {
            QuickBookPickerSheet(viewModel: viewModel, mode: .updateProgress)
                .macSheetFrame()
        }
        .sheet(isPresented: $isShowingSessionPicker) {
            QuickBookPickerSheet(viewModel: viewModel, mode: .readingSession)
                .macSheetFrame()
        }
        .sheet(isPresented: $isShowingQuotePicker) {
            QuickBookPickerSheet(viewModel: viewModel, mode: .quoteScanner)
                .macSheetFrame()
        }
    }
    
    // MARK: - 1. НАСТОЛЬНЫЙ ИНТЕРФЕЙС ДЛЯ MACOS (ПОСТОЯННЫЙ САЙДБАР + ТУЛБАР)
    #if targetEnvironment(macCatalyst) || os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List {
                Section(header: Text("Книжный Рай")) {
                    sidebarItem(tab: .dashboard)
                    sidebarItem(tab: .library, badge: "\(viewModel.books.count)")
                    sidebarItem(tab: .journal, badge: "\(quotesManager.quotes.count)")
                    sidebarItem(tab: .stats)
                    sidebarItem(tab: .sanctuary)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Книжный Рай")
            .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 320)
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
        .navigationSplitViewStyle(.balanced)
    }
    
    private func sidebarItem(tab: AppTab, badge: String? = nil) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 15, weight: selectedTab == tab ? .bold : .medium))
                    .foregroundColor(selectedTab == tab ? .white : theme.primaryAccent)
                    .frame(width: 24, height: 24)
                
                Text(tab.title)
                    .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                    .foregroundColor(selectedTab == tab ? .white : Color(UIColor.label))
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(selectedTab == tab ? .white : theme.primaryAccent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            (selectedTab == tab ? Color.white.opacity(0.25) : theme.primaryAccent.opacity(0.12))
                        )
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(selectedTab == tab ? theme.primaryAccent : Color.clear)
            .cornerRadius(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .desktopHover(scale: 1.02, yOffset: -1)
    }
    #endif
    
    // MARK: - 2. МОБИЛЬНЫЙ ИНТЕРФЕЙС ДЛЯ IPHONE / IPAD (ТАББАР)
    private var iOSLayout: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                DashboardView(viewModel: viewModel)
                    .opacity(selectedTab == .dashboard ? 1 : 0)
                    .allowsHitTesting(selectedTab == .dashboard)

                LibraryView(viewModel: viewModel)
                    .opacity(selectedTab == .library ? 1 : 0)
                    .allowsHitTesting(selectedTab == .library)

                JournalHubView(viewModel: viewModel)
                    .opacity(selectedTab == .journal ? 1 : 0)
                    .allowsHitTesting(selectedTab == .journal)

                DetailedStatsView(viewModel: viewModel)
                    .opacity(selectedTab == .stats ? 1 : 0)
                    .allowsHitTesting(selectedTab == .stats)

                SanctuaryCabinetView(viewModel: viewModel)
                    .opacity(selectedTab == .sanctuary ? 1 : 0)
                    .allowsHitTesting(selectedTab == .sanctuary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        case .journal:
            JournalHubView(viewModel: viewModel)
        case .stats:
            DetailedStatsView(viewModel: viewModel)
        case .sanctuary:
            SanctuaryCabinetView(viewModel: viewModel)
        }
    }
    
    // MARK: - Нижний мобильный таббар с 5 разделами
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .dashboard)
            tabButton(tab: .library)
            tabButton(tab: .journal)
            tabButton(tab: .stats)
            tabButton(tab: .sanctuary)
        }
        .padding(.horizontal, 8)
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
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(selectedTab == tab ? theme.primaryAccent : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                        .keyboardShortcut(.cancelAction)
                }
            }
            .onMacExitCommand {
                dismiss()
            }
            .interactiveDismissDisabled(false)
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

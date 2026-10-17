import SwiftUI

/// Всплывающая универсальная командная палитра читателя (Command Palette Quick HUD / ⌘K)
/// Обеспечивает мгновенный доступ к книгам, цитатам, разделам и системным действиям за доли секунды.
public struct CommandPaletteOverlayView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject public var viewModel: LibraryViewModel
    public let onSelectBook: (Book) -> Void
    public let onNavigateTab: (Int) -> Void
    public let onTriggerAction: (String) -> Void

    @State private var searchText: String = ""
    @State private var selectedCategory: CommandPaletteCategory? = nil
    @FocusState private var isSearchFocused: Bool

    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init(
        viewModel: LibraryViewModel,
        onSelectBook: @escaping (Book) -> Void,
        onNavigateTab: @escaping (Int) -> Void,
        onTriggerAction: @escaping (String) -> Void
    ) {
        self.viewModel = viewModel
        self.onSelectBook = onSelectBook
        self.onNavigateTab = onNavigateTab
        self.onTriggerAction = onTriggerAction
    }

    private var allResults: [CommandPaletteItem] {
        CommandPaletteEngine.search(
            query: searchText,
            books: viewModel.books,
            quotes: QuotesManager.shared.quotes,
            onSelectBook: { book in
                onSelectBook(book)
                dismiss()
            },
            onNavigateTab: { tabIndex in
                onNavigateTab(tabIndex)
                dismiss()
            },
            onTriggerAction: { tag in
                onTriggerAction(tag)
                dismiss()
            }
        )
    }

    private var filteredResults: [CommandPaletteItem] {
        guard let category = selectedCategory else { return allResults }
        return allResults.filter { $0.category == category }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Поле быстрого ввода поиска в стиле Spotlight
                searchBarHeader

                // Фильтры категорий (Все, Действия, Книги, Разделы, Цитаты)
                categoryFilterBar

                Divider()

                // Список результатов
                if filteredResults.isEmpty {
                    emptySearchPlaceholder
                } else {
                    resultsListView
                }

                // Нижний футер с подсказками клавиш
                keyboardHintsFooter
            }
            .navigationTitle("Командная палитра")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(wineAccent)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isSearchFocused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Поле поиска
    private var searchBarHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)

            TextField("Поиск книг, цитат, разделов или действий...", text: $searchText)
                .font(.body)
                .focused($isSearchFocused)
                .submitLabel(.done)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Панель чипов-фильтров категорий
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "Все (\(allResults.count))", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                    HapticManager.shared.lightTap()
                }

                ForEach(CommandPaletteCategory.allCases) { cat in
                    let count = allResults.filter { $0.category == cat }.count
                    if count > 0 {
                        filterChip(title: "\(cat.title) (\(count))", isSelected: selectedCategory == cat) {
                            selectedCategory = cat
                            HapticManager.shared.lightTap()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(isSelected ? .bold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? wineAccent : Color(.tertiarySystemFill))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Список результатов
    private var resultsListView: some View {
        List {
            ForEach(filteredResults) { item in
                Button {
                    HapticManager.shared.lightTap()
                    item.execute()
                } label: {
                    HStack(spacing: 14) {
                        // Иконка категории
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.accentColor.opacity(0.14))
                                .frame(width: 36, height: 36)

                            Image(systemName: item.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(item.accentColor)
                        }

                        // Текст элемента
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)

                            Text(item.subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Бейдж категории
                        Text(item.category.title)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Пустое состояние
    private var emptySearchPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.4))

            Text("Ничего не найдено")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("По запросу «\(searchText)» совпадений не обнаружено. Попробуйте поискать по автору, названию или ключевому слову.")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Подсказки клавиатурных комбинаций
    private var keyboardHintsFooter: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("⌘K")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text("Быстрый вызов")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Text("ESC")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text("Закрыть")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
    }
}

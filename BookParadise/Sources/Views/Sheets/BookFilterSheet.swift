import SwiftUI

public struct BookFilterSheet: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }

    private var matchingBooksCount: Int {
        viewModel.filteredBooks.count
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // 1. Статус чтения
                    filterSection(title: "Статус чтения") {
                        HStack(spacing: 8) {
                            ForEach(ReadingStatus.allCases) { status in
                                let isSelected = viewModel.filterCriteria.statuses.contains(status)
                                filterChip(title: status.rawValue, isSelected: isSelected) {
                                    if isSelected {
                                        viewModel.filterCriteria.statuses.remove(status)
                                    } else {
                                        viewModel.filterCriteria.statuses.insert(status)
                                    }
                                }
                            }
                        }
                    }

                    // 2. Формат книги и файл для Kindle
                    filterSection(title: "Формат издания") {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                ForEach(BookFormat.allCases) { format in
                                    let isSelected = viewModel.filterCriteria.formats.contains(format)
                                    filterChip(title: format.rawValue, icon: format.iconName, isSelected: isSelected) {
                                        if isSelected {
                                            viewModel.filterCriteria.formats.remove(format)
                                        } else {
                                            viewModel.filterCriteria.formats.insert(format)
                                        }
                                    }
                                }
                            }

                            // Тумблер файла Kindle
                            Toggle(isOn: $viewModel.filterCriteria.onlyWithFiles) {
                                HStack(spacing: 8) {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundColor(theme.primaryAccent)
                                    Text("Только с прикреплённым файлом (Kindle)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .tint(theme.primaryAccent)
                            .padding(.vertical, 4)
                        }
                    }

                    // 3. Жанры
                    filterSection(title: "Жанры литературы") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                            ForEach(Genre.allCases) { g in
                                let isSelected = viewModel.filterCriteria.genres.contains(g)
                                filterChip(title: g.rawValue, icon: g.iconName, isSelected: isSelected) {
                                    if isSelected {
                                        viewModel.filterCriteria.genres.remove(g)
                                    } else {
                                        viewModel.filterCriteria.genres.insert(g)
                                    }
                                }
                            }
                        }
                    }

                    // 4. Оценка
                    filterSection(title: "Рейтинг и оценка") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(BookRating.allCases) { rating in
                                    let isSelected = viewModel.filterCriteria.ratings.contains(rating)
                                    filterChip(title: rating.rawValue, isSelected: isSelected) {
                                        if isSelected {
                                            viewModel.filterCriteria.ratings.remove(rating)
                                        } else {
                                            viewModel.filterCriteria.ratings.insert(rating)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 5. Циклы и серийность
                    filterSection(title: "Серии и циклы") {
                        HStack(spacing: 8) {
                            ForEach(CycleFilterMode.allCases) { mode in
                                let isSelected = viewModel.filterCriteria.cycleMode == mode
                                filterChip(title: mode.rawValue, isSelected: isSelected) {
                                    viewModel.filterCriteria.cycleMode = mode
                                }
                            }
                        }
                    }

                    // 6. Объём книги (страницы)
                    filterSection(title: "Объём книги") {
                        HStack(spacing: 8) {
                            ForEach(PageRangeFilter.allCases) { pr in
                                let isSelected = viewModel.filterCriteria.pageRange == pr
                                filterChip(title: pr.rawValue, isSelected: isSelected) {
                                    viewModel.filterCriteria.pageRange = pr
                                }
                            }
                        }
                    }

                    // 7. Полка хранения
                    filterSection(title: "Полка хранения") {
                        HStack(spacing: 8) {
                            ForEach(ShelfStatus.allCases) { shelf in
                                let isSelected = viewModel.filterCriteria.shelves.contains(shelf)
                                filterChip(title: shelf.rawValue, isSelected: isSelected) {
                                    if isSelected {
                                        viewModel.filterCriteria.shelves.remove(shelf)
                                    } else {
                                        viewModel.filterCriteria.shelves.insert(shelf)
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.filterCriteria.isActive {
                        Button("Сбросить") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.filterCriteria.reset()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryAccent)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Плавающая кнопка применения с живым подсчётом
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        Text("Показать \(matchingBooksCount) книг")
                            .fontWeight(.bold)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.primaryAccent, theme.secondaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: theme.primaryAccent.opacity(0.35), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .background(
                    Color(UIColor.systemGroupedBackground)
                        .opacity(0.95)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }

    // MARK: - Вспомогательные компоненты
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    private func filterChip(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .foregroundColor(isSelected ? .white : Color(UIColor.label))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? theme.primaryAccent : Color(UIColor.tertiarySystemFill))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

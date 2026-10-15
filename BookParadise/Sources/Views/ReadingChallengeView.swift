import SwiftUI

public struct ReadingChallengeView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("annualGoalBooks") private var annualGoal: Int = 30
    @State private var customGoalText: String = ""
    @State private var isEditingGoal: Bool = false

    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }

    private var readBooksCount: Int {
        viewModel.stats.readBooks
    }

    private var progressRatio: Double {
        guard annualGoal > 0 else { return 0.0 }
        return min(1.0, Double(readBooksCount) / Double(annualGoal))
    }

    private var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    }

    private var daysInYear: Int { 365 }

    private var expectedBooksByNow: Double {
        Double(annualGoal) * (Double(dayOfYear) / Double(daysInYear))
    }

    private var paceDifference: Double {
        Double(readBooksCount) - expectedBooksByNow
    }

    private var completedBooks: [Book] {
        viewModel.books.filter { $0.status == .read }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Главный прогресс-круг и цель
                    goalProgressCard

                    // 2. Умная аналитика темпа
                    paceAnalyticsCard

                    // 3. Быстрая настройка персональной цели
                    goalSettingCard

                    // 4. Полка завершённых книг года
                    completedBooksShelf

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Книжный вызов 2026")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryAccent)
                }
            }
        }
    }

    // MARK: - 1. Главная карточка прогресса
    private var goalProgressCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Фоновое кольцо
                Circle()
                    .stroke(theme.primaryAccent.opacity(0.12), lineWidth: 16)
                    .frame(width: 190, height: 190)

                // Прогресс кольцо
                Circle()
                    .trim(from: 0, to: CGFloat(progressRatio))
                    .stroke(
                        LinearGradient(
                            colors: [theme.primaryAccent, theme.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 190, height: 190)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressRatio)

                VStack(spacing: 4) {
                    Text("\(readBooksCount)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(Color(UIColor.label))

                    Text("из \(annualGoal) книг")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f%%", progressRatio * 100))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryAccent)
                }
            }
            .frame(width: 200, height: 200)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(max(0, annualGoal - readBooksCount))")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Осталось прочесть")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 30)

                VStack(spacing: 2) {
                    Text("\(daysInYear - dayOfYear)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Дней до конца года")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    // MARK: - 2. Анализ темпа
    private var paceAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: paceDifference >= 0 ? "arrow.up.forward.circle.fill" : "exclamationmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(paceDifference >= 0 ? .green : .orange)

                Text(paceDifference >= 0 ? "Вы опережаете график!" : "Отставание от графика")
                    .font(.headline)
                    .foregroundColor(paceDifference >= 0 ? .green : .orange)
            }

            if paceDifference >= 0 {
                let aheadCount = Int(paceDifference)
                Text("Вы прочитали на \(aheadCount) \(bookWord(for: aheadCount)) больше, чем запланировано на этот день года. Отличный результат!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                let behindCount = Int(abs(paceDifference))
                let remainingBooks = max(1, annualGoal - readBooksCount)
                let remainingDays = max(1, daysInYear - dayOfYear)
                let daysPerBook = remainingDays / remainingBooks

                Text("Отставание от графика: \(behindCount) \(bookWord(for: behindCount)). Чтобы достичь цели из \(annualGoal) книг, читайте примерно по 1 книге каждые \(daysPerBook) дн. (около \(max(1, 350 / max(1, daysPerBook))) стр. в день).")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    // MARK: - 3. Настройка цели
    private var goalSettingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ваша годовая цель")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack {
                Text("Цель на 2026 год:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                HStack(spacing: 12) {
                    Button(action: {
                        if annualGoal > 5 { annualGoal -= 5 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.primaryAccent)
                    }

                    Text("\(annualGoal)")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .frame(minWidth: 44)

                    Button(action: {
                        annualGoal += 5
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.primaryAccent)
                    }
                }
            }

            // Быстрые пресеты
            HStack(spacing: 8) {
                ForEach([20, 30, 40, 50, 75, 100], id: \.self) { preset in
                    let isSelected = annualGoal == preset
                    Button(action: {
                        annualGoal = preset
                    }) {
                        Text("\(preset)")
                            .font(.caption)
                            .fontWeight(isSelected ? .bold : .medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? theme.primaryAccent : Color(UIColor.tertiarySystemFill))
                            .foregroundColor(isSelected ? .white : Color(UIColor.label))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    // MARK: - 4. Полка завершённых книг
    private var completedBooksShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Прочитано в этом году")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Text("\(completedBooks.count) книг")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryAccent)
            }

            if completedBooks.isEmpty {
                Text("Пока нет прочитанных книг в этом году")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(completedBooks) { book in
                            NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    BookCoverView(
                                        coverURL: book.cleanCoverURL,
                                        title: book.title,
                                        author: book.author,
                                        genre: book.genre,
                                        cornerRadius: 8
                                    )
                                    .frame(width: 80, height: 120)

                                    Text(book.title)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .frame(width: 80, alignment: .leading)
                                        .foregroundColor(Color(UIColor.label))

                                    if let rating = book.rating {
                                        Text(rating.rawValue)
                                            .font(.system(size: 9))
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    private func bookWord(for count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        if mod100 >= 11 && mod100 <= 19 { return "книг" }
        if mod10 == 1 { return "книгу" }
        if mod10 >= 2 && mod10 <= 4 { return "книги" }
        return "книг"
    }
}

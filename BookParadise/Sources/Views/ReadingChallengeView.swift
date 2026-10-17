import SwiftUI

public struct ReadingChallengeView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    public var onDismiss: (() -> Void)? = nil

    @AppStorage("annualGoalBooks") private var annualGoal: Int = 30
    @AppStorage("monthlySprintPagesGoal") private var monthlySprintPagesGoal: Int = 400
    @ObservedObject private var sessionManager = ReadingSessionManager.shared

    @State private var isExpandedGrid: Bool = false
    @State private var selectedBookForDetail: Book? = nil
    @State private var sprintGoalInput: String = ""
    @State private var annualGoalInput: String = ""

    public init(viewModel: LibraryViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
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

    private var completedTotalPages: Int {
        completedBooks.reduce(0) { $0 + $1.totalPages }
    }

    private var averageBookPages: Int {
        guard !completedBooks.isEmpty else { return 0 }
        return completedTotalPages / completedBooks.count
    }

    private var topCompletedGenre: String {
        guard !completedBooks.isEmpty else { return "Разное" }
        var counts: [String: Int] = [:]
        for book in completedBooks {
            let g = book.genre.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !g.isEmpty { counts[g, default: 0] += 1 }
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? "Художественная литература"
    }

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: Date()).capitalized
    }

    private var currentMonthPagesRead: Int {
        let cal = Calendar.current
        let now = Date()
        let currentMonth = cal.component(.month, from: now)
        let currentYear = cal.component(.year, from: now)

        let sessionPages = sessionManager.sessionHistory.filter { session in
            let m = cal.component(.month, from: session.date)
            let y = cal.component(.year, from: session.date)
            return m == currentMonth && y == currentYear
        }.reduce(0) { $0 + $1.pagesRead }

        let bookPages = viewModel.books.filter { b in
            b.status == .read && b.monthIndex == currentMonth
        }.reduce(0) { $0 + $1.totalPages }

        return max(sessionPages, bookPages)
    }

    private var sprintRatio: Double {
        guard monthlySprintPagesGoal > 0 else { return 0.0 }
        return min(1.0, Double(currentMonthPagesRead) / Double(monthlySprintPagesGoal))
    }

    private var currentDayOfMonth: Int {
        Calendar.current.component(.day, from: Date())
    }

    private var totalDaysInCurrentMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    private var daysLeftInMonth: Int {
        max(1, totalDaysInCurrentMonth - currentDayOfMonth)
    }

    private var expectedMonthPagesByNow: Double {
        Double(monthlySprintPagesGoal) * (Double(currentDayOfMonth) / Double(totalDaysInCurrentMonth))
    }

    private var neededPagesPerDay: Int {
        let remaining = max(0, monthlySprintPagesGoal - currentMonthPagesRead)
        return Int(ceil(Double(remaining) / Double(daysLeftInMonth)))
    }

    public var body: some View {
        Group {
            if onDismiss != nil {
                NavigationStack {
                    scrollContent
                        .navigationTitle("Книжный вызов 2026")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Готово") {
                                    handleDismiss()
                                }
                                .fontWeight(.bold)
                                .foregroundColor(theme.primaryAccent)
                                .keyboardShortcut(.cancelAction)
                            }
                        }
                        .onExitCommand {
                            handleDismiss()
                        }
                        .interactiveDismissDisabled(false)
                }
            } else {
                scrollContent
                    .navigationTitle("Книжный вызов 2026")
                    .navigationBarTitleDisplayMode(.inline)
                    .onExitCommand {
                        handleDismiss()
                    }
            }
        }
        .sheet(item: $selectedBookForDetail) { book in
            NavigationStack {
                BookDetailView(viewModel: viewModel, bookId: book.id)
            }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Главный прогресс-круг и цель (без обрезки сверху)
                goalProgressCard

                // 2. Умная аналитика темпа
                paceAnalyticsCard

                // 3. Марафон текущего месяца (Спринт с ползунком до 10 000 стр)
                monthlySprintCard

                // 4. Настройка годовой цели (с шагом 1)
                goalSettingCard

                // 5. Полка завершённых книг года (с разворотом в сетку и переходом в детали)
                completedBooksShelf

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func handleDismiss() {
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
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

    // MARK: - 1. Главная карточка прогресса (с запасом высоты)
    private var goalProgressCard: some View {
        VStack(spacing: 16) {
            ZStack {
                // Фоновое кольцо
                Circle()
                    .stroke(theme.primaryAccent.opacity(0.12), lineWidth: 16)
                    .frame(width: 180, height: 180)

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
                    .frame(width: 180, height: 180)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressRatio)

                VStack(spacing: 4) {
                    Text("\(readBooksCount)")
                        .font(.system(size: 46, weight: .black, design: .rounded))
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
            .frame(width: 210, height: 210)
            .padding(.top, 10)

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

    // MARK: - 3. Марафон месяца (Спринт с ползунком и строкой ввода до 10 000 стр)
    private var monthlySprintCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Марафон месяца: \(currentMonthName)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Персональный спринт по страницам")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text("\(Int(sprintRatio * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(sprintRatio >= 1.0 ? .green : .orange)
            }

            // Дорожка спринта с бегуном
            VStack(spacing: 6) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let runnerX = max(10, min(w - 20, CGFloat(sprintRatio) * w))
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                            .frame(height: 10)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(10, CGFloat(sprintRatio) * w), height: 10)

                        Text(sprintRatio >= 1.0 ? "🏆" : "🏃‍♂️")
                            .font(.system(size: 16))
                            .offset(x: runnerX - 10, y: -14)

                        Text("🏁")
                            .font(.system(size: 14))
                            .offset(x: w - 16, y: -14)
                    }
                }
                .frame(height: 24)

                HStack {
                    Text("\(currentMonthPagesRead) стр. прочитано")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Цель: \(monthlySprintPagesGoal) стр.")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }

            // Статус и прогноз спринта
            HStack(spacing: 8) {
                if sprintRatio >= 1.0 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Ура! Цель спринта на \(currentMonthName) выполнена!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                } else if Double(currentMonthPagesRead) >= expectedMonthPagesByNow {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                    Text("Отличный темп! Опережаешь график на \(Int(Double(currentMonthPagesRead) - expectedMonthPagesByNow)) стр.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "target")
                        .foregroundColor(.orange)
                    Text("Чтобы успеть за \(daysLeftInMonth) дн., читай по ~\(neededPagesPerDay) стр./день")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)

            Divider()

            // Ползунок и строка ввода цели до 10 000 страниц
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Настройка цели спринта:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        TextField(
                            "Цель",
                            value: $monthlySprintPagesGoal,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(width: 65)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(6)

                        Text("стр.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Slider(
                    value: Binding(
                        get: { Double(monthlySprintPagesGoal) },
                        set: { monthlySprintPagesGoal = Int($0) }
                    ),
                    in: 50...10000,
                    step: 50
                )
                .tint(.orange)

                HStack {
                    Text("50 стр.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("5 000 стр.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("10 000 стр.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Быстрые пресеты до 10000
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach([300, 500, 1000, 2500, 5000, 10000], id: \.self) { goal in
                            let isSelected = monthlySprintPagesGoal == goal
                            Button(action: {
                                withAnimation { monthlySprintPagesGoal = goal }
                            }) {
                                Text("\(goal) стр")
                                    .font(.caption2)
                                    .fontWeight(isSelected ? .bold : .medium)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(isSelected ? Color.orange : Color(UIColor.tertiarySystemGroupedBackground))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .desktopHover(scale: 1.05, yOffset: -1)
                        }
                    }
                }
                .padding(.top, 2)
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

    // MARK: - 4. Настройка годовой цели (Шаг = 1)
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
                        if annualGoal > 1 { annualGoal -= 1 }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.primaryAccent)
                    }
                    .buttonStyle(.plain)
                    .desktopHover(scale: 1.1, yOffset: -1)

                    HStack(spacing: 2) {
                        TextField(
                            "Цель",
                            value: $annualGoal,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .frame(width: 48)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(6)

                        Text("книг")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        annualGoal += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.primaryAccent)
                    }
                    .buttonStyle(.plain)
                    .desktopHover(scale: 1.1, yOffset: -1)
                }
            }

            // Быстрые пресеты
            HStack(spacing: 8) {
                ForEach([12, 24, 30, 50, 75, 100], id: \.self) { preset in
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
                    .buttonStyle(.plain)
                    .desktopHover(scale: 1.05, yOffset: -1)
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

    // MARK: - 5. Полка завершённых книг (с разворотом в сетку и открытием)
    private var completedBooksShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Прочитано в этом году")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text("\(completedBooks.count) \(bookWord(for: completedBooks.count)) • \(completedTotalPages) стр.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !completedBooks.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpandedGrid.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isExpandedGrid ? "rectangle.grid.1x2" : "square.grid.2x2")
                            Text(isExpandedGrid ? "Свернуть" : "Развернуть сетку")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.primaryAccent.opacity(0.12))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .desktopHover(scale: 1.05, yOffset: -1)
                }
            }

            if completedBooks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "books.vertical")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Пока нет прочитанных книг в этом году")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Статистический срез по завершённым книгам
                HStack(spacing: 12) {
                    statPill(title: "Всего страниц", value: "\(completedTotalPages)", icon: "book.pages")
                    statPill(title: "Средний объём", value: "\(averageBookPages) стр.", icon: "ruler")
                    statPill(title: "Топ жанр", value: topCompletedGenre, icon: "tag.fill")
                }

                if isExpandedGrid {
                    // Развёрнутая адаптивная сетка книг
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 120), spacing: 14)],
                        spacing: 16
                    ) {
                        ForEach(completedBooks) { book in
                            bookCard(for: book, isCompact: false)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    // Компактная горизонтальная карусель
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(completedBooks) { book in
                                bookCard(for: book, isCompact: true)
                            }
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

    private func statPill(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(theme.primaryAccent)
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(UIColor.label))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(UIColor.tertiarySystemFill))
        .cornerRadius(8)
    }

    private func bookCard(for book: Book, isCompact: Bool) -> some View {
        Button(action: {
            selectedBookForDetail = book
        }) {
            VStack(alignment: .leading, spacing: 4) {
                BookCoverView(
                    coverURL: book.cleanCoverURL,
                    title: book.title,
                    author: book.author,
                    genre: book.genre,
                    cornerRadius: 8
                )
                .frame(width: isCompact ? 80 : 120, height: isCompact ? 120 : 175)
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)

                Text(book.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(isCompact ? 1 : 2)
                    .frame(width: isCompact ? 80 : 120, alignment: .leading)
                    .foregroundColor(Color(UIColor.label))

                Text(book.author)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: isCompact ? 80 : 120, alignment: .leading)

                if let rating = book.rating {
                    Text(rating.rawValue)
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                }

                if !isCompact {
                    Text("\(book.totalPages) стр.")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .desktopHover(scale: 1.04, yOffset: -2)
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

import SwiftUI
import UIKit

public struct ReadingWrappedView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @ObservedObject private var quotesManager = QuotesManager.shared

    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Расчет метрик
    private var completedBooks: [Book] {
        viewModel.books.filter { $0.status == .read }
    }

    private var totalPagesRead: Int {
        completedBooks.reduce(0) { $0 + $1.totalPages } +
        viewModel.books.filter { $0.status == .inProgress }.reduce(0) { $0 + $1.pagesRead }
    }

    private var towerHeightCm: Double {
        let pages = Double(totalPagesRead)
        let books = Double(completedBooks.count)
        let height = (pages * 0.008) + (books * 0.4) // 0.08мм страница + 4мм обложка
        return max(0.5, (height * 10).rounded() / 10)
    }

    private var towerComparisonText: String {
        let h = towerHeightCm
        if h < 8 {
            return "Высота чашки эспрессо ☕️"
        } else if h < 20 {
            return "Высота плюшевого медвежонка 🧸"
        } else if h < 38 {
            return "Высота пушистого кота 🐈"
        } else if h < 60 {
            return "Высота журнального столика 🛋️"
        } else {
            return "Настоящий книжный небоскрёб! 🗼"
        }
    }

    private var totalReadingHoursText: String {
        let secs = sessionManager.totalReadingSeconds
        let hours = secs / 3600
        let mins = (secs % 3600) / 60
        if hours > 0 {
            return "\(hours) ч \(mins) мин"
        } else {
            return "\(mins) мин"
        }
    }

    private var topGenre: (genre: Genre, count: Int, percent: Int)? {
        guard !completedBooks.isEmpty else { return nil }
        var genreCounts: [Genre: Int] = [:]
        for b in completedBooks {
            genreCounts[b.genre, default: 0] += 1
        }
        guard let top = genreCounts.max(by: { $0.value < $1.value }) else { return nil }
        let pct = Int(round(Double(top.value) / Double(completedBooks.count) * 100.0))
        return (top.key, top.value, pct)
    }

    private var goldenQuote: BookQuote? {
        quotesManager.quotes.first
    }

    private var shareSummaryText: String {
        var text = """
        📚 Мои книжные итоги в «Книжном Рае»:
        • Прочитано страниц: \(totalPagesRead)
        • Прочитано книг: \(completedBooks.count)
        • Высота книжной башни: \(String(format: "%.1f", towerHeightCm)) см (\(towerComparisonText))
        • Время в концентрации: \(totalReadingHoursText)
        • Самый активный день: \(sessionManager.mostActiveWeekdayString)
        """
        if let tg = topGenre {
            text += "\n• Любимый жанр: \(tg.genre.rawValue) (\(tg.percent)%)"
        }
        if let q = goldenQuote {
            text += "\n\n«\(q.text)»"
        }
        text += "\n\n#КнижныйРай #ReadingWrapped"
        return text
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Карточка-постер
                    posterCard

                    // Кнопка «Поделиться»
                    ShareLink(item: shareSummaryText) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Поделиться книжными итогами")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [theme.primaryAccent, theme.secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: theme.primaryAccent.opacity(0.3), radius: 6, y: 3)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Reading Wrapped")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var posterCard: some View {
        VStack(spacing: 20) {
            // Заголовок карточки
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("КНИЖНЫЙ РАЙ • WRAPPED")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .tracking(1.5)
                        .foregroundColor(theme.primaryAccent)

                    Text("Ваш Литературный Путь")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(theme.primaryAccent)
            }

            Divider()

            // 1. Книжная башня
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.primaryAccent.opacity(0.12))
                        .frame(width: 64, height: 64)

                    Image(systemName: "books.vertical.fill")
                        .font(.title)
                        .foregroundColor(theme.primaryAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("КНИЖНАЯ БАШНЯ")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Text("\(String(format: "%.1f", towerHeightCm)) см")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)

                    Text(towerComparisonText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Статистика объема
            HStack(spacing: 12) {
                metricPill(title: "Страниц", value: "\(totalPagesRead)", icon: "doc.text.fill")
                metricPill(title: "Книг", value: "\(completedBooks.count)", icon: "checkmark.seal.fill")
                metricPill(title: "Времени", value: totalReadingHoursText, icon: "timer")
            }

            Divider()

            // 2. Темпоритм и жанр
            VStack(spacing: 12) {
                HStack {
                    Label("Любимый день недели:", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(sessionManager.mostActiveWeekdayString)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }

                if let tg = topGenre {
                    HStack {
                        Label("Главный жанр:", systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(tg.genre.rawValue) (\(tg.percent)%)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(tg.genre.accentColor)
                    }
                }

                HStack {
                    Label("Средняя скорость:", systemImage: "speedometer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(sessionManager.averageSpeedPagesPerHour)) стр./час")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }

            // 3. Золотая цитата
            if let q = goldenQuote {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("ЗОЛОТАЯ ЦИТАТА")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)

                    Text("«\(q.text)»")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(theme.primaryAccent.opacity(0.06))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private func metricPill(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.primaryAccent)

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

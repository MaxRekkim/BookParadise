import SwiftUI

// MARK: - Интерактивный виджет экономики библиотеки
public struct LibraryEconomicsCardView: View {
    public let books: [Book]
    public let sessions: [ReadingSession]
    
    @State private var selectedCurrency: Currency = .rub
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(books: [Book], sessions: [ReadingSession]) {
        self.books = books
        self.sessions = sessions
    }
    
    private var report: LibraryEconomicsReport {
        LibraryEconomicsEngine.generateReport(
            books: books,
            sessions: sessions,
            currency: selectedCurrency
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок карточки
            HStack(spacing: 8) {
                Image(systemName: "banknote.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Экономика библиотеки")
                    .font(.headline)
                
                Spacer()
                
                // Переключатель валюты
                Picker("Валюта", selection: $selectedCurrency) {
                    ForEach(Currency.allCases) { curr in
                        Text(curr.symbol).tag(curr)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
            }
            
            // Сетка ключевых показателей
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Карточка 1: Общая стоимость
                MetricBox(
                    title: "ИНВЕСТИРОВАНО",
                    value: "\(Int(report.totalInvested)) \(report.currency.symbol)",
                    subtitle: "\(report.totalBooks) книг на полках",
                    icon: "books.vertical.fill",
                    color: .blue
                )
                
                // Карточка 2: Стоимость страницы
                MetricBox(
                    title: "ЦЕНА СТРАНИЦЫ",
                    value: String(format: "%.2f %@", report.costPerPageRead, report.currency.symbol),
                    subtitle: "за 1 прочитанную стр.",
                    icon: "doc.text.fill",
                    color: .purple
                )
                
                // Карточка 3: Стоимость часа
                MetricBox(
                    title: "ЦЕНА ЧАСА ЧТЕНИЯ",
                    value: String(format: "%.1f %@", report.costPerHourRead, report.currency.symbol),
                    subtitle: "\(Int(report.totalHoursRead)) ч. суммарно",
                    icon: "clock.arrow.circlepath",
                    color: .orange
                )
                
                // Карточка 4: Сэкономлено
                MetricBox(
                    title: "СЭКОНОМЛЕНО",
                    value: "+\(Int(report.estimatedLeisureSavings)) \(report.currency.symbol)",
                    subtitle: "vs платный досуг",
                    icon: "sparkles",
                    color: .green
                )
            }
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Чтение — одна из самых высокомаржинальных инвестиций в личное развитие.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Вспомогательный блок метрики
fileprivate struct MetricBox: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

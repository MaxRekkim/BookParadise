import SwiftUI

// MARK: - Карточка аналитики осознанного прекращения чтения (DNF)
public struct DNFAnalyticsCardView: View {
    public let books: [Book]
    
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(books: [Book]) {
        self.books = books
    }
    
    private var report: DNFReport {
        DNFAnalyticsEngine.generateReport(books: books)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок карточки
            HStack(spacing: 8) {
                Image(systemName: "bookmark.slash.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Осознанный отказ от книг (DNF)")
                    .font(.headline)
                
                Spacer()
                
                if report.totalDroppedCount > 0 {
                    Text("\(report.totalDroppedCount) книг")
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
            
            Text("Бросать книги, которые не откликаются — признак зрелого читательского вкуса. Вы сохраняете время для настоящих шедевров.")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            if report.totalDroppedCount > 0 {
                // Сетка метрик
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ТОЧКА ОТКАЗА")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("\(report.averageDropPercentage, specifier: "%.0f")%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("в среднем по книге")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ПРАВИЛО 50 СТР.")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("\(report.ruleOf50ComplianceRate, specifier: "%.0f")%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("шанс дать раскрыться")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("СБЕРЕЖЕНО")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text("\(Int(report.estimatedHoursSaved)) ч")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        Text("для лучших историй")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                // Главная причина
                if let top = report.topReason {
                    HStack(spacing: 6) {
                        Image(systemName: top.iconName)
                            .font(.caption)
                            .foregroundColor(top.color)
                        Text("Частая причина: **\(top.rawValue)**")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("В вашей библиотеке нет заброшенных книг — 100% дочитываемость!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

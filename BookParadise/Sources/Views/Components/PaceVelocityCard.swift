import SwiftUI

// MARK: - Интерактивная карточка темпа чтения и прогноза финиша
public struct PaceVelocityCard: View {
    public let book: Book
    public let sessions: [ReadingSession]
    
    @State private var dailyGoalMinutes: Double = 30.0
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(book: Book, sessions: [ReadingSession]) {
        self.book = book
        self.sessions = sessions
    }
    
    private var forecast: ReadingPaceForecast {
        SmartReadingPaceEngine.calculatePace(
            book: book,
            sessions: sessions,
            dailyGoalMinutes: Int(dailyGoalMinutes)
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок карточки
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .foregroundColor(forecast.paceStatus.color)
                    .font(.title3)
                
                Text("Умный расчёт времени")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: forecast.paceStatus.iconName)
                    Text(forecast.paceStatus.rawValue)
                }
                .font(.caption2)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(forecast.paceStatus.color.opacity(0.15))
                .foregroundColor(forecast.paceStatus.color)
                .clipShape(Capsule())
            }
            
            // Основные метрики
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ОСТАЛОСЬ ЧИТАТЬ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(forecast.formattedTimeRemaining)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(forecast.totalPagesRemaining) стр. до финала")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("СКОРОСТЬ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(forecast.pagesPerHour, specifier: "%.1f")")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("стр/ч")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("≈ \(forecast.wordsPerMinute) слов/мин (WPM)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Прогноз завершения книги
            if forecast.totalPagesRemaining > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flag.checkered")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                        
                        Text("Прогноз финиша:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(forecast.formattedCompletionDate)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    
                    // Интерактивный регулятор ежедневного времени
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("План чтения в день:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(dailyGoalMinutes)) мин/день")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(theme.primaryAccent)
                        }
                        
                        Slider(value: $dailyGoalMinutes, in: 10...120, step: 5)
                            .tint(theme.primaryAccent)
                    }
                }
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

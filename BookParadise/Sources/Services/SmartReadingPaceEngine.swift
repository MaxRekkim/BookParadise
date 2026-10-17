import Foundation
import SwiftUI

// MARK: - Статус темпа чтения
public enum ReadingPaceStatus: String, CaseIterable, Identifiable {
    case fast = "Высокий темп"
    case steady = "Уверенный темп"
    case relaxed = "Спокойное чтение"
    case deep = "Глубокое погружение"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .fast: return "hare.fill"
        case .steady: return "figure.walk"
        case .relaxed: return "cup.and.saucer.fill"
        case .deep: return "water.waves"
        }
    }
    
    public var color: Color {
        switch self {
        case .fast: return .orange
        case .steady: return .green
        case .relaxed: return .blue
        case .deep: return .purple
        }
    }
}

// MARK: - Прогноз темпа и времени завершения
public struct ReadingPaceForecast: Equatable {
    public let pagesPerHour: Double
    public let wordsPerMinute: Int
    public let estimatedMinutesRemaining: Int
    public let formattedTimeRemaining: String
    public let estimatedCompletionDate: Date?
    public let formattedCompletionDate: String
    public let paceStatus: ReadingPaceStatus
    public let totalPagesRemaining: Int
    
    public init(
        pagesPerHour: Double,
        wordsPerMinute: Int,
        estimatedMinutesRemaining: Int,
        formattedTimeRemaining: String,
        estimatedCompletionDate: Date?,
        formattedCompletionDate: String,
        paceStatus: ReadingPaceStatus,
        totalPagesRemaining: Int
    ) {
        self.pagesPerHour = pagesPerHour
        self.wordsPerMinute = wordsPerMinute
        self.estimatedMinutesRemaining = estimatedMinutesRemaining
        self.formattedTimeRemaining = formattedTimeRemaining
        self.estimatedCompletionDate = estimatedCompletionDate
        self.formattedCompletionDate = formattedCompletionDate
        self.paceStatus = paceStatus
        self.totalPagesRemaining = totalPagesRemaining
    }
}

// MARK: - Интеллектуальный вычислительный движок темпа чтения
public struct SmartReadingPaceEngine {
    
    /// Рассчитывает динамический темп и прогноз времени окончания книги
    public static func calculatePace(
        book: Book,
        sessions: [ReadingSession],
        dailyGoalMinutes: Int = 30
    ) -> ReadingPaceForecast {
        let remainingPages = book.remainingPages
        
        // Фильтруем сессии книги или берем общие, если по книге мало данных
        let bookSessions = sessions.filter { $0.bookId == book.id && $0.durationMinutes > 0 && $0.pagesRead > 0 }
        let targetSessions = bookSessions.isEmpty
            ? sessions.filter { $0.durationMinutes > 0 && $0.pagesRead > 0 }
            : bookSessions
        
        let pph: Double
        if targetSessions.isEmpty {
            // Базовый реалистичный темп для взрослого читателя (25-30 стр/час)
            pph = 28.0
        } else {
            // Взвешенное скользящее среднее (недавние сессии имеют больший вес)
            let sorted = targetSessions.sorted(by: { $0.date < $1.date })
            let recent = Array(sorted.suffix(5))
            
            var totalWeightedPPH: Double = 0.0
            var totalWeight: Double = 0.0
            
            for (idx, session) in recent.enumerated() {
                let weight = Double(idx + 1) // 1, 2, 3, 4, 5
                let sessionPPH = (Double(session.pagesRead) / Double(session.durationMinutes)) * 60.0
                totalWeightedPPH += sessionPPH * weight
                totalWeight += weight
            }
            
            let calculated = totalWeightedPPH / max(totalWeight, 1.0)
            // Ограничиваем разумными пределами (от 5 до 120 стр/час)
            pph = min(max(calculated, 5.0), 120.0)
        }
        
        // Примерно 250 слов на типографскую страницу
        let wpm = Int((pph * 250.0) / 60.0)
        
        // Оставшееся чистое время чтения в минутах
        let minutesRemaining: Int
        if remainingPages == 0 {
            minutesRemaining = 0
        } else {
            minutesRemaining = Int(ceil((Double(remainingPages) / pph) * 60.0))
        }
        
        // Форматирование времени
        let formattedRemaining: String
        if remainingPages == 0 {
            formattedRemaining = "Книга прочитана 🎉"
        } else if minutesRemaining < 60 {
            formattedRemaining = "\(minutesRemaining) мин"
        } else {
            let hours = minutesRemaining / 60
            let mins = minutesRemaining % 60
            if mins == 0 {
                formattedRemaining = "\(hours) ч"
            } else {
                formattedRemaining = "\(hours) ч \(mins) мин"
            }
        }
        
        // Определение статуса темпа
        let status: ReadingPaceStatus
        if pph >= 45.0 {
            status = .fast
        } else if pph >= 25.0 {
            status = .steady
        } else if pph >= 15.0 {
            status = .relaxed
        } else {
            status = .deep
        }
        
        // Расчёт даты окончания с учётом ежедневной цели (dailyGoalMinutes)
        let safeDailyMinutes = max(dailyGoalMinutes, 10)
        let daysNeeded = Double(minutesRemaining) / Double(safeDailyMinutes)
        let completionDate = Calendar.current.date(byAdding: .hour, value: Int(ceil(daysNeeded * 24.0)), to: Date())
        
        let formattedDate: String
        if remainingPages == 0 {
            formattedDate = "Завершена"
        } else if let date = completionDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "d MMMM (E)"
            formattedDate = formatter.string(from: date)
        } else {
            formattedDate = "Скоро"
        }
        
        return ReadingPaceForecast(
            pagesPerHour: (pph * 10).rounded() / 10,
            wordsPerMinute: wpm,
            estimatedMinutesRemaining: minutesRemaining,
            formattedTimeRemaining: formattedRemaining,
            estimatedCompletionDate: completionDate,
            formattedCompletionDate: formattedDate,
            paceStatus: status,
            totalPagesRemaining: remainingPages
        )
    }
}

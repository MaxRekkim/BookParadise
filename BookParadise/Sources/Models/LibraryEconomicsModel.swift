import Foundation
import SwiftUI

// MARK: - Валюта
public enum Currency: String, CaseIterable, Identifiable {
    case rub = "₽"
    case usd = "$"
    case eur = "€"
    
    public var id: String { rawValue }
    
    public var symbol: String { rawValue }
    public var title: String {
        switch self {
        case .rub: return "Рубли (₽)"
        case .usd: return "Доллары ($)"
        case .eur: return "Евро (€)"
        }
    }
}

// MARK: - Отчёт по экономике библиотеки
public struct LibraryEconomicsReport: Equatable {
    public let totalBooks: Int
    public let totalInvested: Double
    public let totalPagesRead: Int
    public let totalHoursRead: Double
    public let costPerPageRead: Double
    public let costPerHourRead: Double
    public let estimatedLeisureSavings: Double
    public let currency: Currency
    
    public init(
        totalBooks: Int,
        totalInvested: Double,
        totalPagesRead: Int,
        totalHoursRead: Double,
        costPerPageRead: Double,
        costPerHourRead: Double,
        estimatedLeisureSavings: Double,
        currency: Currency
    ) {
        self.totalBooks = totalBooks
        self.totalInvested = totalInvested
        self.totalPagesRead = totalPagesRead
        self.totalHoursRead = totalHoursRead
        self.costPerPageRead = costPerPageRead
        self.costPerHourRead = costPerHourRead
        self.estimatedLeisureSavings = estimatedLeisureSavings
        self.currency = currency
    }
}

// MARK: - Вычислительный движок экономики библиотеки
public struct LibraryEconomicsEngine {
    
    /// Рассчитывает финансовые метрики владения библиотекой и ценности чтения
    public static func generateReport(
        books: [Book],
        sessions: [ReadingSession],
        paperAveragePrice: Double = 750.0,
        electronicAveragePrice: Double = 350.0,
        currency: Currency = .rub
    ) -> LibraryEconomicsReport {
        let totalCount = books.count
        guard totalCount > 0 else {
            return LibraryEconomicsReport(
                totalBooks: 0,
                totalInvested: 0.0,
                totalPagesRead: 0,
                totalHoursRead: 0.0,
                costPerPageRead: 0.0,
                costPerHourRead: 0.0,
                estimatedLeisureSavings: 0.0,
                currency: currency
            )
        }
        
        // Суммарные инвестиции в книги
        var totalInvested: Double = 0.0
        var totalPagesRead = 0
        
        for book in books {
            totalPagesRead += book.pagesRead
            switch book.format {
            case .paper:
                totalInvested += paperAveragePrice
            case .electronic:
                totalInvested += electronicAveragePrice
            }
        }
        
        // Суммарные часы чтения
        let sessionMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let totalHoursRead: Double
        if sessionMinutes > 0 {
            totalHoursRead = Double(sessionMinutes) / 60.0
        } else {
            // Эвристическая оценка: ~30 страниц в час
            totalHoursRead = Double(totalPagesRead) / 30.0
        }
        
        // Стоимость одной прочитанной страницы
        let costPerPage: Double
        if totalPagesRead > 0 {
            costPerPage = totalInvested / Double(totalPagesRead)
        } else {
            costPerPage = totalInvested
        }
        
        // Стоимость одного часа чтения
        let costPerHour: Double
        if totalHoursRead > 0 {
            costPerHour = totalInvested / totalHoursRead
        } else {
            costPerHour = totalInvested
        }
        
        // Экономия относительно платного досуга (кино, кафе ≈ 400 ₽ в час)
        let benchmarkHourlyRate = currency == .rub ? 400.0 : 15.0
        let alternativeLeisureCost = totalHoursRead * benchmarkHourlyRate
        let estimatedSavings = max(alternativeLeisureCost - totalInvested, 0.0)
        
        return LibraryEconomicsReport(
            totalBooks: totalCount,
            totalInvested: totalInvested,
            totalPagesRead: totalPagesRead,
            totalHoursRead: (totalHoursRead * 10).rounded() / 10,
            costPerPageRead: (costPerPage * 100).rounded() / 100,
            costPerHourRead: (costPerHour * 10).rounded() / 10,
            estimatedLeisureSavings: (estimatedSavings * 10).rounded() / 10,
            currency: currency
        )
    }
}

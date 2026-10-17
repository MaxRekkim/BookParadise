import Foundation
import SwiftUI

// MARK: - Причина прекращения чтения книги
public enum DNFReason: String, CaseIterable, Codable, Identifiable {
    case boringPlot = "Скучный сюжет"
    case tooComplex = "Тяжёлый слог / сложно"
    case badTiming = "Не то время / настроение"
    case poorTranslation = "Слабый перевод"
    case disappointed = "Не оправдала ожиданий"
    case other = "Другая причина"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .boringPlot: return "zzz"
        case .tooComplex: return "brain.head.profile"
        case .badTiming: return "calendar.badge.clock"
        case .poorTranslation: return "character.book.closed"
        case .disappointed: return "hand.thumbsdown"
        case .other: return "ellipsis.circle"
        }
    }
    
    public var color: Color {
        switch self {
        case .boringPlot: return .gray
        case .tooComplex: return .purple
        case .badTiming: return .orange
        case .poorTranslation: return .red
        case .disappointed: return .pink
        case .other: return .blue
        }
    }
}

// MARK: - Запись о брошенной книге
public struct DNFRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let bookId: Int
    public let bookTitle: String
    public let bookAuthor: String
    public let pagesReadBeforeDrop: Int
    public let totalPages: Int
    public let dropPercentage: Double
    public let reason: DNFReason
    public let dateDropped: Date
    
    public init(
        id: UUID = UUID(),
        bookId: Int,
        bookTitle: String,
        bookAuthor: String,
        pagesReadBeforeDrop: Int,
        totalPages: Int,
        reason: DNFReason = .boringPlot,
        dateDropped: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.pagesReadBeforeDrop = pagesReadBeforeDrop
        self.totalPages = max(totalPages, 1)
        self.dropPercentage = (Double(pagesReadBeforeDrop) / Double(max(totalPages, 1))) * 100.0
        self.reason = reason
        self.dateDropped = dateDropped
    }
}

// MARK: - Аналитический отчёт DNF
public struct DNFReport: Equatable {
    public let totalDroppedCount: Int
    public let averageDropPercentage: Double
    public let ruleOf50PagesPassedCount: Int
    public let ruleOf50ComplianceRate: Double // 0.0 ... 100.0
    public let estimatedHoursSaved: Double
    public let topReason: DNFReason?
    public let reasonsBreakdown: [DNFReason: Int]
    
    public init(
        totalDroppedCount: Int,
        averageDropPercentage: Double,
        ruleOf50PagesPassedCount: Int,
        ruleOf50ComplianceRate: Double,
        estimatedHoursSaved: Double,
        topReason: DNFReason?,
        reasonsBreakdown: [DNFReason: Int]
    ) {
        self.totalDroppedCount = totalDroppedCount
        self.averageDropPercentage = averageDropPercentage
        self.ruleOf50PagesPassedCount = ruleOf50PagesPassedCount
        self.ruleOf50ComplianceRate = ruleOf50ComplianceRate
        self.estimatedHoursSaved = estimatedHoursSaved
        self.topReason = topReason
        self.reasonsBreakdown = reasonsBreakdown
    }
}

// MARK: - Движок анализа осознанного отказа от книг
public struct DNFAnalyticsEngine {
    
    /// Генерирует отчёт по брошенным книгам (на основе planMonth == "Заброшено" и пользовательских записей)
    public static func generateReport(books: [Book], records: [DNFRecord] = []) -> DNFReport {
        // Находим книги со статусом «Заброшено»
        let droppedBooks = books.filter { $0.planMonth == "Заброшено" }
        let totalCount = max(droppedBooks.count, records.count)
        
        guard totalCount > 0 else {
            return DNFReport(
                totalDroppedCount: 0,
                averageDropPercentage: 0.0,
                ruleOf50PagesPassedCount: 0,
                ruleOf50ComplianceRate: 0.0,
                estimatedHoursSaved: 0.0,
                topReason: nil,
                reasonsBreakdown: [:]
            )
        }
        
        var dropPercentages: [Double] = []
        var passed50PagesCount = 0
        var unreadPagesTotal = 0
        var reasonsMap: [DNFReason: Int] = [:]
        for r in DNFReason.allCases {
            reasonsMap[r] = 0
        }
        
        // Анализируем книги
        for book in droppedBooks {
            let pct = (Double(book.pagesRead) / Double(max(book.totalPages, 1))) * 100.0
            dropPercentages.append(pct)
            if book.pagesRead >= 50 || pct >= 20.0 {
                passed50PagesCount += 1
            }
            unreadPagesTotal += max(book.totalPages - book.pagesRead, 0)
            
            // Если для книги есть детальная запись — учитываем причину
            if let matchedRecord = records.first(where: { $0.bookId == book.id }) {
                reasonsMap[matchedRecord.reason, default: 0] += 1
            } else {
                reasonsMap[.boringPlot, default: 0] += 1
            }
        }
        
        // Для оставшихся изолированных записей
        for record in records where !droppedBooks.contains(where: { $0.id == record.bookId }) {
            dropPercentages.append(record.dropPercentage)
            if record.pagesReadBeforeDrop >= 50 || record.dropPercentage >= 20.0 {
                passed50PagesCount += 1
            }
            unreadPagesTotal += max(record.totalPages - record.pagesReadBeforeDrop, 0)
            reasonsMap[record.reason, default: 0] += 1
        }
        
        let validDrops = max(dropPercentages.count, 1)
        let avgPct = dropPercentages.reduce(0.0, +) / Double(validDrops)
        let ruleOf50Rate = (Double(passed50PagesCount) / Double(validDrops)) * 100.0
        
        // Экономия времени: ~30 страниц в час
        let hoursSaved = Double(unreadPagesTotal) / 30.0
        let topReason = reasonsMap.max(by: { $0.value < $1.value })?.key
        
        return DNFReport(
            totalDroppedCount: validDrops,
            averageDropPercentage: (avgPct * 10).rounded() / 10,
            ruleOf50PagesPassedCount: passed50PagesCount,
            ruleOf50ComplianceRate: (ruleOf50Rate * 10).rounded() / 10,
            estimatedHoursSaved: (hoursSaved * 10).rounded() / 10,
            topReason: topReason,
            reasonsBreakdown: reasonsMap
        )
    }
}

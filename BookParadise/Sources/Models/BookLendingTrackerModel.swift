import Foundation
import SwiftUI

// MARK: - Состояние книги при выдаче и возврате
public enum BookPhysicalCondition: String, Codable, CaseIterable {
    case mint = "Идеальное"
    case good = "Отличное"
    case fair = "Хорошее"
    case worn = "Потрёпанное"
    case damaged = "Повреждённое"
    
    public var iconName: String {
        switch self {
        case .mint: return "sparkles"
        case .good: return "checkmark.seal.fill"
        case .fair: return "book.closed.fill"
        case .worn: return "exclamationmark.triangle.fill"
        case .damaged: return "bandage.fill"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .mint: return .purple
        case .good: return .green
        case .fair: return .blue
        case .worn: return .orange
        case .damaged: return .red
        }
    }
    
    public var conditionScore: Double {
        switch self {
        case .mint: return 1.0
        case .good: return 0.9
        case .fair: return 0.75
        case .worn: return 0.5
        case .damaged: return 0.2
        }
    }
}

// MARK: - Уровни доверия заёмщика
public enum LendingTrustTier: String, Codable {
    case platinumGuardian = "Платиновый хранитель"
    case reliableReader = "Надёжный читатель"
    case casualBorrower = "Обычный заёмщик"
    case highRisk = "Зона риска"
    
    public var iconName: String {
        switch self {
        case .platinumGuardian: return "rosette"
        case .reliableReader: return "hand.thumbsup.fill"
        case .casualBorrower: return "person.fill"
        case .highRisk: return "exclamationmark.shield.fill"
        }
    }
    
    public var tierColor: Color {
        switch self {
        case .platinumGuardian: return .purple
        case .reliableReader: return .green
        case .casualBorrower: return .blue
        case .highRisk: return .red
        }
    }
}

// MARK: - Математический движок рейтинга доверия
public struct LendingTrustScoreEngine {
    /// Расчёт доверия заёмщика R ∈ [0, 100]
    public static func calculateTrustScore(
        totalLoans: Int,
        onTimeReturns: Int,
        activeOverdue: Int,
        damagedReturns: Int
    ) -> (score: Double, tier: LendingTrustTier) {
        guard totalLoans > 0 else {
            return (100.0, .reliableReader) // По умолчанию доверие высокое до первых нарушений
        }
        
        let ratio = Double(onTimeReturns) / Double(totalLoans)
        var rawScore = (ratio * 100.0) - (Double(activeOverdue) * 15.0) - (Double(damagedReturns) * 20.0)
        let clampedScore = max(0.0, min(100.0, rawScore))
        
        let tier: LendingTrustTier
        switch clampedScore {
        case 90.0...100.0:
            tier = .platinumGuardian
        case 75.0..<90.0:
            tier = .reliableReader
        case 50.0..<75.0:
            tier = .casualBorrower
        default:
            tier = .highRisk
        }
        
        return (clampedScore, tier)
    }
    
    /// Генерация RFC 5545 iCalendar (.ics) файла для Apple Calendar
    public static func generateCalendarEventICS(
        bookTitle: String,
        borrowerName: String,
        dueDate: Date,
        notes: String? = nil
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        
        let nowString = formatter.string(from: Date())
        let dueString = formatter.string(from: dueDate)
        let dueEndString = formatter.string(from: dueDate.addingTimeInterval(3600)) // 1 час события
        let uid = UUID().uuidString
        
        let summary = "Книжный Рай: Возврат «\(bookTitle)» от \(borrowerName)"
        let description = notes ?? "Напоминание о возврате книги из вашей библиотеки."
        
        var ics = "BEGIN:VCALENDAR\r\n"
        ics += "VERSION:2.0\r\n"
        ics += "PRODID:-//BookParadise//Apple-Grade Lending Tracker 3.3//RU\r\n"
        ics += "CALSCALE:GREGORIAN\r\n"
        ics += "METHOD:PUBLISH\r\n"
        ics += "BEGIN:VEVENT\r\n"
        ics += "UID:\(uid)\r\n"
        ics += "DTSTAMP:\(nowString)\r\n"
        ics += "DTSTART:\(dueString)\r\n"
        ics += "DTEND:\(dueEndString)\r\n"
        ics += "SUMMARY:\(summary)\r\n"
        ics += "DESCRIPTION:\(description)\r\n"
        ics += "BEGIN:VALARM\r\n"
        ics += "ACTION:DISPLAY\r\n"
        ics += "DESCRIPTION:Книга «\(bookTitle)» должна быть возвращена сегодня!\r\n"
        ics += "TRIGGER:-PT2H\r\n" // За 2 часа до срока
        ics += "END:VALARM\r\n"
        ics += "END:VEVENT\r\n"
        ics += "END:VCALENDAR\r\n"
        
        return ics
    }
}

import Foundation
import SwiftUI

// MARK: - Литературная эпоха
public enum LiteraryEpoch: String, CaseIterable, Identifiable {
    case antiquity = "Античность"
    case middleAges = "Средневековье и Ренессанс"
    case enlightenment = "Просвещение и Классицизм"
    case goldenAge = "Золотой XIX век"
    case modernism = "Модернизм и XX век"
    case contemporary = "XXI век и Современность"
    case futureSciFi = "Будущее и Научная фантастика"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .antiquity: return "building.columns.fill"
        case .middleAges: return "shield.fill"
        case .enlightenment: return "feather.fill"
        case .goldenAge: return "theatermasks.fill"
        case .modernism: return "clock.arrow.circlepath"
        case .contemporary: return "sparkles"
        case .futureSciFi: return "rocket.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .antiquity: return .orange
        case .middleAges: return .indigo
        case .enlightenment: return .teal
        case .goldenAge: return .brown
        case .modernism: return .blue
        case .contemporary: return .green
        case .futureSciFi: return .purple
        }
    }
    
    public var eraPeriodString: String {
        switch self {
        case .antiquity: return "до 500 г. н.э."
        case .middleAges: return "500 — 1650"
        case .enlightenment: return "1650 — 1800"
        case .goldenAge: return "1801 — 1900"
        case .modernism: return "1901 — 2000"
        case .contemporary: return "2001 — настоящее"
        case .futureSciFi: return "Далекое будущее"
        }
    }
}

// MARK: - Кластер книг эпохи
public struct EpochCluster: Identifiable, Equatable {
    public var id: String { epoch.rawValue }
    public let epoch: LiteraryEpoch
    public let books: [Book]
    public let percentage: Double
    
    public init(epoch: LiteraryEpoch, books: [Book], percentage: Double) {
        self.epoch = epoch
        self.books = books
        self.percentage = percentage
    }
}

// MARK: - Движок хронологической оси литературы
public struct TimeTravelAxisEngine {
    
    /// Определяет эпоху книги на основе жанра, года в издании или автора
    public static func determineEpoch(for book: Book) -> LiteraryEpoch {
        // Проверяем явный жанр фантастики с футуристическим сеттингом
        if book.genre == .sciFiAltHistory {
            let lower = (book.title + " " + book.edition).lowercased()
            if lower.contains("будущее") || lower.contains("20") || lower.contains("кибер") || lower.contains("космос") {
                return .futureSciFi
            }
        }
        
        // Поиск 4-значного года в издании или описании
        let regex = try? NSRegularExpression(pattern: "\\b(1[0-9]{3}|20[0-2][0-9])\\b")
        let fullText = "\(book.edition) \(book.title)"
        if let match = regex?.firstMatch(in: fullText, range: NSRange(fullText.startIndex..., in: fullText)),
           let range = Range(match.range, in: fullText),
           let year = Int(fullText[range]) {
            if year <= 500 { return .antiquity }
            if year <= 1650 { return .middleAges }
            if year <= 1800 { return .enlightenment }
            if year <= 1900 { return .goldenAge }
            if year <= 2000 { return .modernism }
            return .contemporary
        }
        
        // Эвристика по авторам классики
        let authorLower = book.author.lowercased()
        if authorLower.contains("гомер") || authorLower.contains("платон") || authorLower.contains("аристотель") || authorLower.contains("сенека") || authorLower.contains("марк аврелий") {
            return .antiquity
        }
        if authorLower.contains("данте") || authorLower.contains("шекспир") || authorLower.contains("бокаччо") || authorLower.contains("сервантес") {
            return .middleAges
        }
        if authorLower.contains("гёте") || authorLower.contains("вольтер") || authorLower.contains("руссо") || authorLower.contains("кант") {
            return .enlightenment
        }
        if authorLower.contains("пушкин") || authorLower.contains("толстой") || authorLower.contains("достоевский") || authorLower.contains("чехов") || authorLower.contains("диккенс") || authorLower.contains("тургенев") || authorLower.contains("гоголь") || authorLower.contains("дюма") {
            return .goldenAge
        }
        if authorLower.contains("булгаков") || authorLower.contains("набоков") || authorLower.contains("оруэлл") || authorLower.contains("ремарк") || authorLower.contains("хемингуэй") || authorLower.contains("брэдбери") || authorLower.contains("бродский") || authorLower.contains("довлатов") {
            return .modernism
        }
        
        // По жанру классической прозы по умолчанию относим к Золотому веку / XX веку
        if book.genre == .classicProse {
            return .goldenAge
        }
        
        // По умолчанию для современных изданий
        return .contemporary
    }
    
    /// Группирует книги по эпохам с подсчётом долей
    public static func clusterBooksByEpoch(books: [Book]) -> [EpochCluster] {
        let totalCount = max(books.count, 1)
        var mapping: [LiteraryEpoch: [Book]] = [:]
        for e in LiteraryEpoch.allCases {
            mapping[e] = []
        }
        
        for book in books {
            let epoch = determineEpoch(for: book)
            mapping[epoch, default: []].append(book)
        }
        
        return LiteraryEpoch.allCases.compactMap { epoch in
            let clusterBooks = mapping[epoch] ?? []
            guard !clusterBooks.isEmpty else { return nil }
            let pct = (Double(clusterBooks.count) / Double(totalCount)) * 100.0
            return EpochCluster(epoch: epoch, books: clusterBooks, percentage: pct)
        }
    }
}

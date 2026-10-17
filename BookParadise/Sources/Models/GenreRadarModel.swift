import Foundation
import SwiftUI

// MARK: - Точка данных для жанрового радара
public struct GenreRadarPoint: Identifiable, Equatable {
    public var id: String { genre.rawValue }
    public let genre: Genre
    public let count: Int
    public let percentage: Double // 0.0 ... 100.0
    public let normalizedRadius: Double // 0.0 ... 1.0 для отрисовки вершин полигона
    
    public init(genre: Genre, count: Int, percentage: Double, normalizedRadius: Double) {
        self.genre = genre
        self.count = count
        self.percentage = percentage
        self.normalizedRadius = normalizedRadius
    }
}

// MARK: - Архетип читательского разнообразия
public enum ReadingArchetype: String, CaseIterable, Identifiable {
    case polymath = "Универсальный Энциклопедист"
    case explorer = "Любознательный Исследователь"
    case specialist = "Фокусированный Специалист"
    case purist = "Преданный Ценитель"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .polymath: return "sparkles"
        case .explorer: return "safari.fill"
        case .specialist: return "scope"
        case .purist: return "heart.circle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .polymath: return .purple
        case .explorer: return .teal
        case .specialist: return .indigo
        case .purist: return .pink
        }
    }
    
    public var description: String {
        switch self {
        case .polymath:
            return "Идеальный баланс между литературой разных направлений. Вы легко переходите от сложного нон-фикшна к готике и поэзии."
        case .explorer:
            return "Широкий кругозор: вы открыты новым жанрам, регулярно пробуете незнакомые сеттинги и расширяете горизонты."
        case .specialist:
            return "Глубокое погружение в 2–3 любимых жанра. Вы цените экспертность и системный подход к темам."
        case .purist:
            return "Абсолютная верность одному направлению. Вы точно знаете, что дарит вам максимальное удовольствие от чтения."
        }
    }
}

// MARK: - Итоговый отчет жанрового радара
public struct GenreRadarReport: Equatable {
    public let points: [GenreRadarPoint]
    public let shannonEntropy: Double // 0.0 ... 1.0
    public let topGenre: Genre?
    public let archetype: ReadingArchetype
    public let totalBooksCount: Int
    
    public init(points: [GenreRadarPoint], shannonEntropy: Double, topGenre: Genre?, archetype: ReadingArchetype, totalBooksCount: Int) {
        self.points = points
        self.shannonEntropy = shannonEntropy
        self.topGenre = topGenre
        self.archetype = archetype
        self.totalBooksCount = totalBooksCount
    }
}

// MARK: - Вычислительный движок жанрового радара
public struct GenreRadarEngine {
    
    /// Анализирует книги и рассчитывает индекс разнообразия Шеннона и точки паутинной диаграммы
    public static func generateReport(from books: [Book]) -> GenreRadarReport {
        let totalCount = books.count
        guard totalCount > 0 else {
            let zeroPoints = Genre.allCases.map {
                GenreRadarPoint(genre: $0, count: 0, percentage: 0.0, normalizedRadius: 0.0)
            }
            return GenreRadarReport(
                points: zeroPoints,
                shannonEntropy: 0.0,
                topGenre: nil,
                archetype: .purist,
                totalBooksCount: 0
            )
        }
        
        // Подсчёт количества книг по каждому жанру
        var counts: [Genre: Int] = [:]
        for g in Genre.allCases {
            counts[g] = 0
        }
        for book in books {
            counts[book.genre, default: 0] += 1
        }
        
        let maxCount = counts.values.max() ?? 1
        let safeMax = max(maxCount, 1)
        
        // Вычисление энтропии Шеннона: H = - sum(p_i * ln(p_i))
        var entropySum: Double = 0.0
        let k = Double(Genre.allCases.count)
        let maxPossibleEntropy = log(k)
        
        for (_, count) in counts {
            if count > 0 {
                let p = Double(count) / Double(totalCount)
                entropySum -= p * log(p)
            }
        }
        
        let normalizedEntropy: Double
        if maxPossibleEntropy > 0.0001 {
            normalizedEntropy = min(max(entropySum / maxPossibleEntropy, 0.0), 1.0)
        } else {
            normalizedEntropy = 0.0
        }
        
        // Определение архетипа
        let archetype: ReadingArchetype
        if normalizedEntropy >= 0.82 {
            archetype = .polymath
        } else if normalizedEntropy >= 0.60 {
            archetype = .explorer
        } else if normalizedEntropy >= 0.35 {
            archetype = .specialist
        } else {
            archetype = .purist
        }
        
        // Определение ведущего жанра
        let topGenre = counts.max(by: { $0.value < $1.value })?.key
        
        // Формирование точек для отображения
        let points = Genre.allCases.map { genre -> GenreRadarPoint in
            let c = counts[genre] ?? 0
            let pct = (Double(c) / Double(totalCount)) * 100.0
            // Нормализованный радиус от 0.0 до 1.0 относительно максимального значения для красивой геометрии
            let rad = Double(c) / Double(safeMax)
            return GenreRadarPoint(genre: genre, count: c, percentage: pct, normalizedRadius: rad)
        }
        
        return GenreRadarReport(
            points: points,
            shannonEntropy: normalizedEntropy,
            topGenre: topGenre,
            archetype: archetype,
            totalBooksCount: totalCount
        )
    }
}

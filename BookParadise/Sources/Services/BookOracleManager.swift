import Foundation
import SwiftUI

public enum ReadingMood: String, CaseIterable, Identifiable {
    case any = "Любое"
    case cozy = "Уют и тепло"
    case thrilling = "Острый сюжет"
    case intellectual = "Интеллект"
    case emotional = "Драма и чувства"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .any: return "sparkles"
        case .cozy: return "cup.and.saucer.fill"
        case .thrilling: return "flame.fill"
        case .intellectual: return "brain.head.profile"
        case .emotional: return "heart.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .any: return .purple
        case .cozy: return .orange
        case .thrilling: return .red
        case .intellectual: return .blue
        case .emotional: return .pink
        }
    }

    public var subtitle: String {
        switch self {
        case .any: return "Всё разнообразие библиотеки"
        case .cozy: return "Согревающая проза, сказки, лёгкая классика"
        case .thrilling: return "Детективы, триллеры, приключения, динамика"
        case .intellectual: return "Философия, нон-фикшн, история, наука"
        case .emotional: return "Глубокие переживания, романтика, поэзия"
        }
    }
}

public enum AvailableReadingTime: String, CaseIterable, Identifiable {
    case any = "Любое"
    case short = "15–30 мин"
    case medium = "1–2 часа"
    case deep = "Вечер / Эпос"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .any: return "clock"
        case .short: return "bolt.fill"
        case .medium: return "hourglass"
        case .deep: return "moon.stars.fill"
        }
    }

    public var subtitle: String {
        switch self {
        case .any: return "Без ограничений по страницам"
        case .short: return "Тонкие книги или близкий финал"
        case .medium: return "Книги среднего объема (200–350 стр.)"
        case .deep: return "Масштабные произведения от 400+ стр."
        }
    }
}

public enum OracleQueueSource: String, CaseIterable, Identifiable {
    case planned = "В планах"
    case inProgress = "Читаю сейчас"
    case cycle = "Циклы"
    case all = "Вся библиотека"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .planned: return "bookmark.fill"
        case .inProgress: return "book.fill"
        case .cycle: return "link"
        case .all: return "books.vertical.fill"
        }
    }
}

public struct BookRecommendation: Identifiable {
    public let id = UUID()
    public let book: Book
    public let mood: ReadingMood
    public let time: AvailableReadingTime
    public let justification: String
    public let estimatedTimeToFinish: String
}

public class BookOracleManager: ObservableObject {
    public static let shared = BookOracleManager()

    private init() {}

    public func recommend(
        from books: [Book],
        mood: ReadingMood,
        time: AvailableReadingTime,
        source: OracleQueueSource
    ) -> BookRecommendation? {
        guard !books.isEmpty else { return nil }

        // 1. Фильтрация по источнику
        var candidates: [Book] = []
        switch source {
        case .planned:
            candidates = books.filter { $0.status == .toRead }
        case .inProgress:
            candidates = books.filter { $0.status == .reading }
        case .cycle:
            candidates = books.filter { ($0.cycle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) && $0.status != .completed }
        case .all:
            candidates = books.filter { $0.status != .completed }
        }

        if candidates.isEmpty {
            candidates = books.filter { $0.status != .completed }
        }
        if candidates.isEmpty {
            candidates = books
        }

        // 2. Скоринг кандидатов
        var scored: [(book: Book, score: Double, justification: String)] = []

        for b in candidates {
            var score = Double.random(in: 0...2) // случайный фактор разнообразия
            var reasons: [String] = []

            // Оценка жанра по настроению
            switch mood {
            case .any:
                score += 5
            case .cozy:
                if [.classic, .novel, .children, .ya].contains(b.genre) {
                    score += 15
                    reasons.append("жанр «\(b.genre.rawValue)» создаст теплое и комфортное настроение")
                }
            case .thrilling:
                if [.detective, .thriller, .fantasy, .scifi, .adventures].contains(b.genre) {
                    score += 15
                    reasons.append("«\(b.genre.rawValue)» увлечет динамичным сюжетом без пауз")
                }
            case .intellectual:
                if [.nonfiction, .science, .philosophy, .biography, .history, .psychology].contains(b.genre) {
                    score += 15
                    reasons.append("«\(b.genre.rawValue)» подарит пищу для глубоких размышлений")
                }
            case .emotional:
                if [.poetry, .drama, .novel, .ya].contains(b.genre) {
                    score += 15
                    reasons.append("книга наполнена сильными эмоциями и тонкими переживаниями")
                }
            }

            // Оценка объема по времени
            let pages = b.remainingPages > 0 ? b.remainingPages : b.totalPages
            switch time {
            case .any:
                score += 5
            case .short:
                if pages <= 180 || b.remainingPages <= 60 {
                    score += 14
                    reasons.append("объем всего \(pages) стр. идеально подходит для короткого чтения")
                }
            case .medium:
                if pages > 180 && pages <= 380 {
                    score += 14
                    reasons.append("комфортный объем (\(pages) стр.) не перегрузит ваш вечер")
                }
            case .deep:
                if pages > 380 || (b.cycle != nil && !b.cycle!.isEmpty) {
                    score += 14
                    reasons.append("масштабный объем (\(pages) стр.) позволит полностью раствориться в сюжете")
                }
            }

            // Дополнительные бонусы
            if b.status == .toRead {
                score += 4
            }
            if let rating = b.rating, rating == .fiveStars {
                score += 6
            }
            if let cycle = b.cycle, !cycle.isEmpty {
                score += 3
                reasons.append("часть серии «\(cycle)»")
            }

            let justification: String
            if !reasons.isEmpty {
                let joined = reasons.joined(separator: ", ")
                justification = "Книжный сомелье рекомендует эту книгу, так как \(joined)."
            } else {
                justification = "Прекрасный выбор для чтения прямо сейчас из вашей домашней библиотеки."
            }

            scored.append((b, score, justification))
        }

        guard let best = scored.max(by: { $0.score < $1.score }) else { return nil }

        let timeToFinish = ReadingSessionManager.shared.estimatedTimeToFinish(remainingPages: best.book.remainingPages).displayString

        return BookRecommendation(
            book: best.book,
            mood: mood,
            time: time,
            justification: best.justification,
            estimatedTimeToFinish: timeToFinish
        )
    }

    public func rollDice(from books: [Book]) -> BookRecommendation? {
        let unread = books.filter { $0.status == .toRead }
        let pool = unread.isEmpty ? books : unread
        guard let randomBook = pool.randomElement() else { return nil }

        let timeToFinish = ReadingSessionManager.shared.estimatedTimeToFinish(remainingPages: randomBook.remainingPages).displayString

        return BookRecommendation(
            book: randomBook,
            mood: .any,
            time: .any,
            justification: "Случайный жребий оракула пал на эту книгу. Время стряхнуть с неё пыль и открыть первую страницу!",
            estimatedTimeToFinish: timeToFinish
        )
    }
}

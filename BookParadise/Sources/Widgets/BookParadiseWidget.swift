import SwiftUI
import UIKit
#if canImport(WidgetKit)
import WidgetKit

public struct BookParadiseEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetDataSnapshot

    public init(date: Date, snapshot: WidgetDataSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

public struct BookParadiseProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> BookParadiseEntry {
        let dummyBook = WidgetBookSnapshot(
            book: Book(
                id: 1,
                title: "Внутри убийцы",
                author: "Майк Омер",
                pagesRead: 215,
                totalPages: 416,
                status: .inProgress
            )
        )
        return BookParadiseEntry(
            date: Date(),
            snapshot: WidgetDataSnapshot(currentBook: dummyBook, totalReadCount: 77, annualGoal: 100)
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (BookParadiseEntry) -> Void) {
        let snapshot = WidgetDataExporter.shared.loadSnapshot() ?? placeholder(in: context).snapshot
        completion(BookParadiseEntry(date: Date(), snapshot: snapshot))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<BookParadiseEntry>) -> Void) {
        let snapshot = WidgetDataExporter.shared.loadSnapshot() ?? placeholder(in: context).snapshot
        let entry = BookParadiseEntry(date: Date(), snapshot: snapshot)
        // Обновлять каждые 30 минут
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Виджет Small (Маленький)
public struct BookParadiseSmallWidgetView: View {
    public let entry: BookParadiseEntry
    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init(entry: BookParadiseEntry) {
        self.entry = entry
    }

    public var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)

            if let book = entry.snapshot.currentBook {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.caption2)
                            .foregroundColor(wineAccent)
                        Text("ЧИТАЮ")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(wineAccent)
                        Spacer()
                        Text("\(Int(book.progressPercent))%")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(wineAccent)
                    }

                    Text(book.title)
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(2)
                        .foregroundColor(.primary)

                    Text(book.author)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    // Прогресс
                    VStack(alignment: .leading, spacing: 3) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.secondary.opacity(0.2))
                                Capsule().fill(wineAccent)
                                    .frame(width: geo.size.width * CGFloat(min(1.0, book.progressPercent / 100.0)))
                            }
                        }
                        .frame(height: 5)

                        HStack {
                            Text("\(book.pagesRead)/\(book.totalPages) с.")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("-\(book.remainingPages)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(wineAccent)
                        }
                    }
                }
                .padding(12)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(wineAccent)
                    Text("Книжный Рай")
                        .font(.system(size: 12, weight: .bold))
                    Text("Прочитано: \(entry.snapshot.totalReadCount) книг")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

// MARK: - Виджет Medium (Средний)
public struct BookParadiseMediumWidgetView: View {
    public let entry: BookParadiseEntry
    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init(entry: BookParadiseEntry) {
        self.entry = entry
    }

    public var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)

            HStack(spacing: 14) {
                if let book = entry.snapshot.currentBook {
                    // Левая колонка: книга
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "book.pages.fill")
                                .font(.caption2)
                                .foregroundColor(wineAccent)
                            Text("АКТИВНОЕ ЧТЕНИЕ")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(wineAccent)
                        }

                        Text(book.title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(2)

                        Text(book.author)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        VStack(alignment: .leading, spacing: 3) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.secondary.opacity(0.2))
                                    Capsule().fill(wineAccent)
                                        .frame(width: geo.size.width * CGFloat(min(1.0, book.progressPercent / 100.0)))
                                }
                            }
                            .frame(height: 6)

                            HStack {
                                Text("\(book.pagesRead) из \(book.totalPages) стр.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(book.progressPercent))%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(wineAccent)
                            }
                        }
                    }

                    Divider()

                    // Правая колонка: статистика и мотивация
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Цель года")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }

                        Text("\(entry.snapshot.totalReadCount) книг")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.primary)

                        Text("из \(entry.snapshot.annualGoal) запланированных")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("«Чтение — это разговор с лучшими людьми прошедших веков»")
                            .font(.system(size: 9, design: .serif))
                            .italic()
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: 130)
                } else {
                    VStack(alignment: .center, spacing: 8) {
                        Text("✨ Книжный Рай")
                            .font(.headline)
                        Text("Прочитано: \(entry.snapshot.totalReadCount) книг")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Конфигурация виджета для Extension
#if WIDGET_EXTENSION
public struct BookParadiseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public var entry: BookParadiseEntry

    public init(entry: BookParadiseEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            BookParadiseSmallWidgetView(entry: entry)
        case .systemMedium:
            BookParadiseMediumWidgetView(entry: entry)
        default:
            BookParadiseSmallWidgetView(entry: entry)
        }
    }
}

public struct BookParadiseWidget: Widget {
    public let kind: String = "BookParadiseWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookParadiseProvider()) { entry in
            BookParadiseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Книжный Рай")
        .description("Отслеживайте прогресс чтения текущей книги прямо на главном экране iOS.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
#endif
#endif

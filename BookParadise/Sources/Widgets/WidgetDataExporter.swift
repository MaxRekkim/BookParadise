import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

public struct WidgetBookSnapshot: Codable {
    public var id: Int
    public var title: String
    public var author: String
    public var coverURL: String?
    public var pagesRead: Int
    public var totalPages: Int
    public var progressPercent: Double
    public var remainingPages: Int

    public init(book: Book) {
        self.id = book.id
        self.title = book.title
        self.author = book.author
        self.coverURL = book.cleanCoverURL?.absoluteString
        self.pagesRead = book.pagesRead
        self.totalPages = book.totalPages
        self.progressPercent = book.progressPercent
        self.remainingPages = book.remainingPages
    }
}

public struct WidgetDataSnapshot: Codable {
    public var currentBook: WidgetBookSnapshot?
    public var totalReadCount: Int
    public var annualGoal: Int
    public var lastUpdated: Date

    public init(currentBook: WidgetBookSnapshot?, totalReadCount: Int, annualGoal: Int = 50) {
        self.currentBook = currentBook
        self.totalReadCount = totalReadCount
        self.annualGoal = annualGoal
        self.lastUpdated = Date()
    }
}

public class WidgetDataExporter {
    public static let shared = WidgetDataExporter()
    public static let appGroupName = "group.com.maxim.bookparadise"
    private let fileName = "BookParadiseWidgetData.json"

    private var sharedContainerURL: URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupName) {
            return container.appendingPathComponent(fileName)
        }
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }

    public func export(books: [Book]) {
        let readingNow = books.first(where: { $0.status == .inProgress })
        let readCount = books.filter { $0.status == .read }.count

        let snapshot = WidgetDataSnapshot(
            currentBook: readingNow != nil ? WidgetBookSnapshot(book: readingNow!) : nil,
            totalReadCount: readCount,
            annualGoal: 50
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: sharedContainerURL, options: Data.WritingOptions.atomic)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        } catch {
            print("Failed to export widget data: \(error)")
        }
    }

    public func loadSnapshot() -> WidgetDataSnapshot? {
        guard FileManager.default.fileExists(atPath: sharedContainerURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: sharedContainerURL)
            return try JSONDecoder().decode(WidgetDataSnapshot.self, from: data)
        } catch {
            print("Failed to load widget snapshot: \(error)")
            return nil
        }
    }
}

import Foundation
import SwiftUI
#if canImport(CoreSpotlight)
import CoreSpotlight
#endif
#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

// MARK: - Метаданные книги для индексации в Spotlight
public struct SpotlightBookMetadata: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var author: String
    public var genre: String
    public var progressPercent: Double
    public var userRating: String?
    public var quotesCount: Int
    public var keywords: [String]
    
    public init(
        id: UUID = UUID(),
        title: String,
        author: String,
        genre: String,
        progressPercent: Double,
        userRating: String? = "Шедевр",
        quotesCount: Int = 5,
        keywords: [String] = []
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.progressPercent = progressPercent
        self.userRating = userRating
        self.quotesCount = quotesCount
        self.keywords = keywords
    }
    
    public var deepLinkURL: URL? {
        URL(string: "bookparadise://book?id=\(id.uuidString)")
    }
}

// MARK: - Сервис глубокой индексации Spotlight
public final class CoreSpotlightIndexer: ObservableObject {
    public static let shared = CoreSpotlightIndexer()
    
    public static let domainIdentifier = "com.maxim.bookparadise.books"
    
    @Published public var indexedCount: Int = 0
    @Published public var isIndexing: Bool = false
    @Published public var lastIndexedDate: Date? = nil
    
    private init() {
        self.indexedCount = 5 // Initial sample count
    }
    
    // MARK: - Индексация массива книг
    public func indexBooks(_ books: [SpotlightBookMetadata]) {
        isIndexing = true
        
        #if canImport(CoreSpotlight)
        var searchableItems: [CSSearchableItem] = []
        
        for book in books {
            let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
            attributeSet.title = book.title
            attributeSet.displayName = book.title
            attributeSet.contentDescription = "\(book.author) • \(book.genre) • Прочитано \(Int(book.progressPercent))%"
            attributeSet.creator = book.author
            attributeSet.genre = book.genre
            attributeSet.keywords = [book.title, book.author, book.genre] + book.keywords
            
            let item = CSSearchableItem(
                uniqueIdentifier: book.id.uuidString,
                domainIdentifier: Self.domainIdentifier,
                attributeSet: attributeSet
            )
            searchableItems.append(item)
        }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { [weak self] error in
            DispatchQueue.main.async {
                self?.isIndexing = false
                if error == nil {
                    self?.indexedCount = books.count
                    self?.lastIndexedDate = Date()
                }
            }
        }
        #else
        DispatchQueue.main.async {
            self.isIndexing = false
            self.indexedCount = books.count
            self.lastIndexedDate = Date()
        }
        #endif
    }
    
    // MARK: - Очистка индекса
    public func clearIndex() {
        #if canImport(CoreSpotlight)
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [Self.domainIdentifier]) { [weak self] _ in
            DispatchQueue.main.async {
                self?.indexedCount = 0
            }
        }
        #else
        DispatchQueue.main.async {
            self.indexedCount = 0
        }
        #endif
    }
    
    public static var sampleIndexCatalog: [SpotlightBookMetadata] {
        [
            SpotlightBookMetadata(
                title: "Мастер и Маргарита",
                author: "Михаил Булгаков",
                genre: "Классика",
                progressPercent: 56.0,
                userRating: "Шедевр",
                quotesCount: 8,
                keywords: ["воланд", "маргарита", "пилат", "москва"]
            ),
            SpotlightBookMetadata(
                title: "Преступление и наказание",
                author: "Фёдор Достоевский",
                genre: "Классика",
                progressPercent: 100.0,
                userRating: "Шедевр",
                quotesCount: 12,
                keywords: ["раскольников", "соня", "петербург"]
            ),
            SpotlightBookMetadata(
                title: "В поисках утраченного времени",
                author: "Марсель Пруст",
                genre: "Модернизм",
                progressPercent: 32.0,
                userRating: "Любимое",
                quotesCount: 6,
                keywords: ["память", "время", "максим"]
            ),
            SpotlightBookMetadata(
                title: "1984",
                author: "Джордж Оруэлл",
                genre: "Антиутопия",
                progressPercent: 100.0,
                userRating: "Шедевр",
                quotesCount: 15,
                keywords: ["уинстон", "партия", "новояз"]
            ),
            SpotlightBookMetadata(
                title: "Сто лет одиночества",
                author: "Габриэль Гарсиа Маркес",
                genre: "Магический реализм",
                progressPercent: 78.0,
                userRating: "Любимое",
                quotesCount: 9,
                keywords: ["макондо", "буэндиа", "дождь"]
            )
        ]
    }
}

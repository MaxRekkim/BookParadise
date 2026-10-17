import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

// MARK: - Модель криптографического книжного луча (Book Beam) для AirDrop и обмена
public struct BookBeamPayload: Codable, Equatable {
    public let version: String
    public let exportTimestamp: Date
    public let bookTitle: String
    public let author: String
    public let isbn: String?
    public let totalPages: Int
    public let genre: String
    public let ratingStars: Int
    public let reviewText: String?
    public let favoriteQuote: String?
    public let readingPacePPH: Double?
    public var integritySha256: String
    
    public init(
        version: String = "3.3.0",
        exportTimestamp: Date = Date(),
        bookTitle: String,
        author: String,
        isbn: String? = nil,
        totalPages: Int,
        genre: String,
        ratingStars: Int = 5,
        reviewText: String? = nil,
        favoriteQuote: String? = nil,
        readingPacePPH: Double? = nil
    ) {
        self.version = version
        self.exportTimestamp = exportTimestamp
        self.bookTitle = bookTitle
        self.author = author
        self.isbn = isbn
        self.totalPages = totalPages
        self.genre = genre
        self.ratingStars = ratingStars
        self.reviewText = reviewText
        self.favoriteQuote = favoriteQuote
        self.readingPacePPH = readingPacePPH
        
        let contentToHash = "\(bookTitle)|\(author)|\(totalPages)|\(genre)|\(ratingStars)|\(reviewText ?? "")"
        self.integritySha256 = Self.computeSha256(contentToHash)
    }
    
    // Проверка целостности данных
    public var isValidIntegrity: Bool {
        let contentToHash = "\(bookTitle)|\(author)|\(totalPages)|\(genre)|\(ratingStars)|\(reviewText ?? "")"
        let calculated = Self.computeSha256(contentToHash)
        return calculated.caseInsensitiveCompare(integritySha256) == .orderedSame
    }
    
    // Вычисление SHA-256 хэша
    public static func computeSha256(_ input: String) -> String {
        #if canImport(CryptoKit)
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
        #else
        // Fallback для окружений без CryptoKit
        var hash = 5381
        for byte in input.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return String(format: "%016x", abs(hash))
        #endif
    }
    
    // Экспорт во временный файл .bookbeam для UIActivityViewController / AirDrop
    public func exportToTemporaryFile() -> URL? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            
            let sanitizedTitle = bookTitle.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
            let fileName = "BookBeam_\(sanitizedTitle).bookbeam"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    // Импорт из файла или данных
    public static func importFrom(data: Data) -> BookBeamPayload? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BookBeamPayload.self, from: data)
    }
}

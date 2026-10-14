import Foundation

public struct GoogleBookInfo {
    public var title: String?
    public var author: String?
    public var pageCount: Int?
    public var thumbnailURL: String?
    public var publisher: String?
}

public class GoogleBooksLookupService {
    public static let shared = GoogleBooksLookupService()
    
    private init() {}
    
    public func lookupISBN(_ isbn: String) async -> GoogleBookInfo? {
        let clean = isbn.replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !clean.isEmpty, let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=isbn:\(clean)") else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]],
                  let first = items.first,
                  let volumeInfo = first["volumeInfo"] as? [String: Any] else {
                return nil
            }
            
            let title = volumeInfo["title"] as? String
            let authors = (volumeInfo["authors"] as? [String])?.joined(separator: ", ")
            let pageCount = volumeInfo["pageCount"] as? Int
            let publisher = volumeInfo["publisher"] as? String
            
            var imageURL: String? = nil
            if let imageLinks = volumeInfo["imageLinks"] as? [String: String] {
                imageURL = imageLinks["thumbnail"] ?? imageLinks["smallThumbnail"]
                if let secure = imageURL?.replacingOccurrences(of: "http://", with: "https://") {
                    imageURL = secure
                }
            }
            
            return GoogleBookInfo(
                title: title,
                author: authors,
                pageCount: pageCount,
                thumbnailURL: imageURL,
                publisher: publisher
            )
        } catch {
            print("Google Books lookup error: \(error)")
            return nil
        }
    }
}

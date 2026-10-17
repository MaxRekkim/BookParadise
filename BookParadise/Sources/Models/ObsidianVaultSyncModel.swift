import Foundation
import SwiftUI

// MARK: - Модель синхронизации с хранилищем Obsidian (PKM Vault)
public struct ObsidianVaultDocument: Identifiable, Codable, Equatable {
    public let id: UUID
    public var filename: String
    public var relativePath: String
    public var frontmatterYAML: String
    public var markdownBody: String
    public var wikilinks: [String]
    
    public init(
        id: UUID = UUID(),
        filename: String,
        relativePath: String,
        frontmatterYAML: String,
        markdownBody: String,
        wikilinks: [String] = []
    ) {
        self.id = id
        self.filename = filename
        self.relativePath = relativePath
        self.frontmatterYAML = frontmatterYAML
        self.markdownBody = markdownBody
        self.wikilinks = wikilinks
    }
    
    public var fullDocumentContent: String {
        "---\n\(frontmatterYAML)\n---\n\n\(markdownBody)"
    }
}

// MARK: - Движок генерации Markdown для Obsidian (ObsidianVaultSyncEngine)
public struct ObsidianVaultSyncEngine {
    
    public static func generateBookDocument(
        title: String,
        author: String,
        genre: String,
        pagesRead: Int,
        totalPages: Int,
        ratingString: String,
        quotes: [(text: String, page: Int)],
        notes: [String]
    ) -> ObsidianVaultDocument {
        let cleanTitle = title.replacingOccurrences(of: "/", with: "-")
        let filename = "\(cleanTitle).md"
        let relPath = "Books/\(filename)"
        
        let tagsYAML = "tags:\n  - #books/\(genre.lowercased())\n  - #author/\(author.replacingOccurrences(of: " ", with: "_").lowercased())"
        let frontmatter = """
        title: "\(title)"
        author: "[[\(author)]]"
        genre: "\(genre)"
        pages_read: \(pagesRead)
        total_pages: \(totalPages)
        rating: "\(ratingString)"
        \(tagsYAML)
        updated: "\(Date().ISO8601Format())"
        """
        
        var body = "# \(title)\n\n"
        body += "Автор: [[\(author)]]\n"
        body += "Прогресс: \(pagesRead) / \(totalPages) стр. (\(Int((Double(pagesRead) / Double(max(totalPages, 1))) * 100))%)\n\n"
        
        if !quotes.isEmpty {
            body += "## 🖋️ Цитаты\n\n"
            for q in quotes {
                body += "> [!quote] Стр. \(q.page)\n> \(q.text)\n\n"
            }
        }
        
        if !notes.isEmpty {
            body += "## 📝 Заметки и Рефлексия\n\n"
            for n in notes {
                body += "> [!note] Заметка\n> \(n)\n\n"
            }
        }
        
        let links = [author] + notes.compactMap { note -> String? in
            guard note.contains("[[") && note.contains("]]") else { return nil }
            return nil
        }
        
        return ObsidianVaultDocument(
            filename: filename,
            relativePath: relPath,
            frontmatterYAML: frontmatter,
            markdownBody: body,
            wikilinks: links
        )
    }
    
    public static var sampleDocument: ObsidianVaultDocument {
        generateBookDocument(
            title: "Мастер и Маргарита",
            author: "Михаил Булгаков",
            genre: "Классика",
            pagesRead: 215,
            totalPages: 384,
            ratingString: "Шедевр",
            quotes: [("Рукописи не горят.", 287), ("Трусость — самый страшный порок.", 310)],
            notes: ["Образ Воланда переосмысляет веймарского Мефистофеля через призму советской Москвы."]
        )
    }
}

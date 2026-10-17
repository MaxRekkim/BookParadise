import Foundation
import SwiftUI

// MARK: - Поддерживаемые форматы сторонних библиотек
public enum ExternalLibrarySourceFormat: String, CaseIterable, Identifiable {
    case goodreads = "Goodreads (CSV)"
    case livelib = "LiveLib (CSV)"
    case storygraph = "StoryGraph (CSV/JSON)"
    case bookparadiseNative = "BookParadise (.json)"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .goodreads: return "books.vertical.fill"
        case .livelib: return "bookmark.fill"
        case .storygraph: return "chart.xyaxis.line"
        case .bookparadiseNative: return "sparkles"
        }
    }
}

// MARK: - Сводка импорта
public struct LibraryImportSummary: Equatable {
    public var totalProcessed: Int
    public var importedBooksCount: Int
    public var skippedDuplicatesCount: Int
    public var sourceFormat: ExternalLibrarySourceFormat
    
    public init(
        totalProcessed: Int = 0,
        importedBooksCount: Int = 0,
        skippedDuplicatesCount: Int = 0,
        sourceFormat: ExternalLibrarySourceFormat = .goodreads
    ) {
        self.totalProcessed = totalProcessed
        self.importedBooksCount = importedBooksCount
        self.skippedDuplicatesCount = skippedDuplicatesCount
        self.sourceFormat = sourceFormat
    }
}

// MARK: - Парсер CSV и JSON
public struct UniversalLibraryDataImporter {
    
    public static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentToken = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentToken.trimmingCharacters(in: .whitespacesAndNewlines))
                currentToken = ""
            } else {
                currentToken.append(char)
            }
        }
        result.append(currentToken.trimmingCharacters(in: .whitespacesAndNewlines))
        return result
    }
    
    public static func detectFormat(fromHeader header: String) -> ExternalLibrarySourceFormat {
        let lower = header.lowercased()
        if lower.contains("my rating") && lower.contains("number of pages") {
            return .goodreads
        } else if lower.contains("моя оценка") || lower.contains("название книги") {
            return .livelib
        } else if lower.contains("storygraph") {
            return .storygraph
        }
        return .goodreads
    }
    
    public static func importCSVData(_ csvContent: String, existingTitles: Set<String> = []) -> (books: [(title: String, author: String, pages: Int, rating: Int)], summary: LibraryImportSummary) {
        let lines = csvContent.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else {
            return ([], LibraryImportSummary())
        }
        
        let header = lines[0]
        let format = detectFormat(fromHeader: header)
        
        var imported: [(title: String, author: String, pages: Int, rating: Int)] = []
        var duplicates = 0
        
        for i in 1..<lines.count {
            let row = parseCSVLine(lines[i])
            guard row.count >= 3 else { continue }
            
            let title = row[0].replacingOccurrences(of: "\"", with: "")
            let author = row[1].replacingOccurrences(of: "\"", with: "")
            let pages = Int(row.count > 2 ? row[2] : "0") ?? 250
            let rating = Int(row.count > 3 ? row[3] : "5") ?? 5
            
            if existingTitles.contains(title.lowercased()) {
                duplicates += 1
            } else {
                imported.append((title, author, pages, rating))
            }
        }
        
        let summary = LibraryImportSummary(
            totalProcessed: lines.count - 1,
            importedBooksCount: imported.count,
            skippedDuplicatesCount: duplicates,
            sourceFormat: format
        )
        return (imported, summary)
    }
}

import Foundation
import UIKit

public struct MarkdownExportService {
    public static let shared = MarkdownExportService()

    private init() {}

    // MARK: - Экспорт одной книги в Markdown (Obsidian / Notion)
    public func exportBookToMarkdown(book: Book, quotes: [BookQuote]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())

        var md = ""

        // YAML Frontmatter для Obsidian / Logseq / Notion
        md += "---\n"
        md += "title: \"\(escapeYaml(book.title))\"\n"
        md += "author: \"\(escapeYaml(book.author))\"\n"
        md += "genre: \"\(escapeYaml(book.genre.rawValue))\"\n"
        md += "status: \"\(book.status.rawValue)\"\n"
        md += "pages_read: \(book.pagesRead)\n"
        md += "total_pages: \(book.totalPages)\n"
        md += "progress_percent: \(book.progressPercent)\n"
        if let rating = book.rating {
            md += "rating: \"\(escapeYaml(rating.rawValue))\"\n"
        }
        md += "format: \"\(book.format.rawValue)\"\n"
        md += "shelf: \"\(book.shelf.rawValue)\"\n"
        if !book.edition.isEmpty {
            md += "edition: \"\(escapeYaml(book.edition))\"\n"
        }
        if !book.isbn.isEmpty {
            md += "isbn: \"\(escapeYaml(book.isbn))\"\n"
        }
        if book.hasCycle {
            md += "cycle: \"\(escapeYaml(book.cycleName))\"\n"
            md += "cycle_number: \"\(escapeYaml(book.cycleNumber))\"\n"
        }
        md += "export_date: \"\(todayStr)\"\n"
        md += "source: \"BookParadise\"\n"
        md += "---\n\n"

        // Заголовок
        md += "# \(book.title)\n\n"
        md += "**Автор:** \(book.author)  \n"
        md += "**Жанр:** \(book.genre.rawValue) | **Формат:** \(book.format.rawValue)  \n"
        if book.hasCycle {
            md += "**Серия:** \(book.cycleName) (книга № \(book.cycleNumber))  \n"
        }
        md += "**Прогресс:** \(book.pagesRead) из \(book.totalPages) стр. (\(book.displayProgressString))  \n"
        if let rating = book.rating {
            md += "**Оценка:** \(rating.rawValue)  \n"
        }
        md += "\n---\n\n"

        // Рецензия и впечатления
        if let review = book.review, !review.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            md += "## Рецензия и личные впечатления\n\n"
            md += "\(review.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
            md += "---\n\n"
        }

        // Сохраненные цитаты
        let bookQuotes = quotes.filter { $0.bookId == book.id }
        if !bookQuotes.isEmpty {
            md += "## Избранные цитаты (\(bookQuotes.count))\n\n"
            for (idx, q) in bookQuotes.enumerated() {
                md += "> «\(q.text)»\n>\n"
                var meta: [String] = []
                if let p = q.pageNumber, p > 0 {
                    meta.append("Стр. \(p)")
                }
                meta.append(formatter.string(from: q.dateAdded))
                md += "> *— \(meta.joined(separator: " • "))*\n\n"

                if let note = q.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    md += "💡 **Заметка:** *\(note.trimmingCharacters(in: .whitespacesAndNewlines))*\n\n"
                }

                if idx < bookQuotes.count - 1 {
                    md += "---\n\n"
                }
            }
        }

        return md
    }

    // MARK: - Экспорт сводного каталога всей библиотеки
    public func exportCatalogToMarkdown(books: [Book], quotes: [BookQuote]) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: Date())

        var md = "# Книжный Рай — Каталог библиотеки\n\n"
        md += "*Экспортировано: \(todayStr) • Всего книг: \(books.count)*\n\n"

        let readBooks = books.filter { $0.status == .read }
        let inProgress = books.filter { $0.status == .inProgress }
        let planned = books.filter { $0.status == .notStarted }

        md += "## Сводка\n"
        md += "- **Прочитано:** \(readBooks.count)\n"
        md += "- **Читаю сейчас:** \(inProgress.count)\n"
        md += "- **В планах:** \(planned.count)\n"
        md += "- **Сохранено цитат:** \(quotes.count)\n\n"

        md += "## Список книг\n\n"
        md += "| Название | Автор | Жанр | Статус | Стр. | Оценка |\n"
        md += "|---|---|---|---|---|---|\n"

        for b in books.sorted(by: { $0.title < $1.title }) {
            let ratingStr = b.rating?.rawValue ?? "-"
            md += "| \(escapePipe(b.title)) | \(escapePipe(b.author)) | \(b.genre.rawValue) | \(b.status.rawValue) | \(b.pagesRead)/\(b.totalPages) | \(ratingStr) |\n"
        }

        return md
    }

    // MARK: - Создание временного файла для шаринга
    public func createTemporaryMarkdownFile(content: String, filename: String) -> URL? {
        let cleanName = filename.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(cleanName).md")

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write temporary markdown file: \(error)")
            return nil
        }
    }

    private func escapeYaml(_ str: String) -> String {
        return str.replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func escapePipe(_ str: String) -> String {
        return str.replacingOccurrences(of: "|", with: "\\|")
    }
}

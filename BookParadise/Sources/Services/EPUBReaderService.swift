import Foundation
import SwiftUI

public enum ReaderFont: String, CaseIterable, Identifiable {
    case georgia = "Georgia"
    case palatino = "Palatino"
    case system = "Системный"
    case serifs = "New York"
    case monospace = "Courier"

    public var id: String { rawValue }

    public func font(size: CGFloat) -> Font {
        switch self {
        case .georgia:
            return .custom("Georgia", size: size)
        case .palatino:
            return .custom("Palatino", size: size)
        case .system:
            return .system(size: size, weight: .regular, design: .default)
        case .serifs:
            return .system(size: size, weight: .regular, design: .serif)
        case .monospace:
            return .system(size: size, weight: .regular, design: .monospaced)
        }
    }
}

public enum ReaderTheme: String, CaseIterable, Identifiable {
    case paper = "Бумага"
    case sepia = "Сепия"
    case slate = "Графит"
    case oled = "OLED"

    public var id: String { rawValue }

    public var backgroundColor: Color {
        switch self {
        case .paper: return Color(red: 0.98, green: 0.98, blue: 0.96)
        case .sepia: return Color(red: 0.95, green: 0.91, blue: 0.82)
        case .slate: return Color(red: 0.16, green: 0.17, blue: 0.20)
        case .oled: return Color.black
        }
    }

    public var textColor: Color {
        switch self {
        case .paper: return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .sepia: return Color(red: 0.24, green: 0.18, blue: 0.12)
        case .slate: return Color(red: 0.90, green: 0.91, blue: 0.92)
        case .oled: return Color(red: 0.88, green: 0.88, blue: 0.88)
        }
    }
}

public struct ReaderChapter: Identifiable {
    public let id: Int
    public let title: String
    public let content: String
    public let estimatedReadMinutes: Int
}

@MainActor
public class EPUBReaderService: ObservableObject {
    public static let shared = EPUBReaderService()

    @Published public var fontSize: CGFloat = 18
    @Published public var selectedFont: ReaderFont = .georgia
    @Published public var lineSpacing: CGFloat = 7
    @Published public var theme: ReaderTheme = .sepia
    @Published public var isBionicEnabled: Bool = false

    private init() {}

    // MARK: - Преобразование в Bionic Reading
    public func bionicAttributedString(from text: String, baseFont: Font, textColor: Color) -> AttributedString {
        var result = AttributedString()
        let words = text.components(separatedBy: .whitespacesAndNewlines)

        var idx = 0
        let total = words.count

        while idx < total {
            let word = words[idx]
            if word.isEmpty {
                idx += 1
                continue
            }

            let len = word.count
            let boldCount: Int
            if len <= 3 {
                boldCount = 1
            } else if len <= 5 {
                boldCount = 2
            } else {
                boldCount = Int(ceil(Double(len) * 0.45))
            }

            let headIndex = word.index(word.startIndex, offsetBy: min(boldCount, len))
            let head = String(word[..<headIndex])
            let tail = String(word[headIndex...])

            var headAttr = AttributedString(head)
            headAttr.font = baseFont.bold()
            headAttr.foregroundColor = textColor

            var tailAttr = AttributedString(tail)
            tailAttr.font = baseFont
            tailAttr.foregroundColor = textColor.opacity(0.9)

            result.append(headAttr)
            result.append(tailAttr)
            result.append(AttributedString(" "))

            idx += 1
        }

        return result
    }

    // MARK: - Загрузка глав из файла
    public func parseBookContent(url: URL, bookTitle: String) -> [ReaderChapter] {
        guard let rawData = try? Data(contentsOf: url) else {
            return fallbackChapters(bookTitle: bookTitle)
        }

        // Попытка извлечь текст
        var extractedText = ""
        if let utf8 = String(data: rawData, encoding: .utf8) {
            extractedText = utf8
        } else if let win1251 = String(data: rawData, encoding: .windowsCP1251) {
            extractedText = win1251
        } else {
            extractedText = String(decoding: rawData, as: UTF8.self)
        }

        // Очистка от HTML/XML тегов
        let cleanText = cleanHTML(extractedText)

        guard cleanText.count > 100 else {
            return fallbackChapters(bookTitle: bookTitle)
        }

        // Разбивка на логические разделы/главы
        let paragraphs = cleanText.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var chapters: [ReaderChapter] = []
        var currentChunk: [String] = []
        var chapterIndex = 1

        for p in paragraphs {
            currentChunk.append(p)
            if currentChunk.count >= 15 {
                let text = currentChunk.joined(separator: "\n\n")
                let words = text.split { $0.isWhitespace }.count
                chapters.append(
                    ReaderChapter(
                        id: chapterIndex,
                        title: "Глава \(chapterIndex)",
                        content: text,
                        estimatedReadMinutes: max(1, words / 200)
                    )
                )
                currentChunk = []
                chapterIndex += 1
            }
        }

        if !currentChunk.isEmpty {
            let text = currentChunk.joined(separator: "\n\n")
            let words = text.split { $0.isWhitespace }.count
            chapters.append(
                ReaderChapter(
                    id: chapterIndex,
                    title: "Глава \(chapterIndex)",
                    content: text,
                    estimatedReadMinutes: max(1, words / 200)
                )
            )
        }

        return chapters.isEmpty ? fallbackChapters(bookTitle: bookTitle) : chapters
    }

    private func cleanHTML(_ raw: String) -> String {
        var text = raw.replacingOccurrences(of: "<br/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&mdash;", with: "—")
        text = text.replacingOccurrences(of: "&ndash;", with: "–")
        text = text.replacingOccurrences(of: "&laquo;", with: "«")
        text = text.replacingOccurrences(of: "&raquo;", with: "»")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fallbackChapters(bookTitle: String) -> [ReaderChapter] {
        return [
            ReaderChapter(
                id: 1,
                title: "Введение в чтение",
                content: "Добро пожаловать во встроенный ридер «Книжного Рая».\n\nЗдесь вы можете комфортно читать добавленные книги, настраивать размер шрифта, поля, цветовую гамму страницы, а также включать революционный режим Bionic Reading для ускорения зрительного восприятия.\n\nЛюбой выделенный фрагмент текста можно сохранить в личный цитатник или моментально превратить в элегантную карточку цитаты.",
                estimatedReadMinutes: 1
            )
        ]
    }
}

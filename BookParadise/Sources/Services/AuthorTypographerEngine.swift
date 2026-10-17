import Foundation

/// Движок микротипографики и оптического форматирования имен авторов и книжных заголовков.
/// Разработан по высочайшим стандартам русского книгоиздания и Apple Human Interface Guidelines.
public struct AuthorTypographerEngine {

    /// Узкий неразрывный пробел (Narrow No-Break Space, U+202F) для склейки между инициалами
    public static let thinNBSP = "\u{202F}"
    
    /// Стандартный неразрывный пробел (No-Break Space, U+00A0) для привязки инициалов к фамилии и предлогов к словам
    public static let nbsp = "\u{00A0}"

    /// Список коротких служебных слов (предлоги, союзы, частицы), которые запрещено оставлять в конце строки
    public static let shortWordsToBind: Set<String> = [
        "и", "в", "во", "на", "с", "со", "к", "ко", "о", "об", "обо", "у", "за", "из", "по",
        "под", "над", "до", "от", "для", "при", "про", "без", "сквозь", "через",
        "а", "но", "да", "или", "либо", "как", "что", "где", "чем",
        "не", "ни", "же", "ли", "бы",
        "the", "a", "an", "of", "in", "on", "at", "to", "for", "by", "with", "and", "or", "but"
    ]

    /// Нормализует имя автора:
    /// - Превращает обычные пробелы между инициалами в узкие неразрывные шпации (`Л. Н. Толстой`)
    /// - Привязывает инициалы к фамилии неразрывным пробелом, исключая разрыв строки
    /// - Корректно форматирует как прямой ("Л. Н. Толстой"), так и инвертированный ("Толстой Л. Н.") порядок
    public static func formatAuthor(_ author: String) -> String {
        let trimmed = author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var result = trimmed

        // 1. Склейка слипшихся инициалов: "Л.Н." -> "Л. Н." или "Дж.Р.Р." -> "Дж. Р. Р."
        // Поддерживает как кириллицу, так и латиницу, включая двухбуквенные сокращения вроде "Дж."
        result = result.replacingOccurrences(
            of: "([А-ЯA-Z][а-яa-z]?\\.)([А-ЯA-Z])",
            with: "$1 $2",
            options: .regularExpression
        )

        // 2. Обработка инициалов перед фамилией: "(И1.) (И2.) Фамилия" -> "И1. И2. Фамилия"
        // Тройные инициалы: "Дж. Р. Р. Толкин" -> "Дж. Р. Р. Толкин"
        let tripleInitialsPrefix = "([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-Яа-яA-Za-z\\-]+)"
        result = result.replacingOccurrences(
            of: tripleInitialsPrefix,
            with: "$1\(thinNBSP)$2\(thinNBSP)$3\(nbsp)$4",
            options: .regularExpression
        )

        // Двойные инициалы: "Л. Н. Толстой" -> "Л. Н. Толстой"
        let doubleInitialsPrefix = "([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-Яа-яA-Za-z\\-]+)"
        result = result.replacingOccurrences(
            of: doubleInitialsPrefix,
            with: "$1\(thinNBSP)$2\(nbsp)$3",
            options: .regularExpression
        )

        // Одиночный инициал: "А. Пушкин" -> "А. Пушкин"
        let singleInitialPrefix = "([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-Яа-яA-Za-z\\-]+)"
        result = result.replacingOccurrences(
            of: singleInitialPrefix,
            with: "$1\(nbsp)$2",
            options: .regularExpression
        )

        // 3. Обработка инициалов после фамилии: "Толстой Л. Н." -> "Толстой Л. Н."
        let doubleInitialsSuffix = "([А-Яа-яA-Za-z\\-]+)[ \\t]+([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-ЯA-Z][а-яa-z]?\\.)"
        result = result.replacingOccurrences(
            of: doubleInitialsSuffix,
            with: "$1\(nbsp)$2\(thinNBSP)$3",
            options: .regularExpression
        )

        let singleInitialSuffix = "([А-Яа-яA-Za-z\\-]+)[ \\t]+([А-ЯA-Z][а-яa-z]?\\.)"
        result = result.replacingOccurrences(
            of: singleInitialSuffix,
            with: "$1\(nbsp)$2",
            options: .regularExpression
        )

        return result
    }

    /// Нормализует книжный заголовок:
    /// - Привязывает короткие предлоги и союзы неразрывным пробелом к следующему слову (устранение висячих предлогов)
    /// - Заменяет прямые кавычки на книжные «ёлочки»
    /// - Заменяет одиночный дефис с пробелами на длинное тире ` — ` с неразрывным пробелом слева
    public static func formatTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var result = trimmed

        // 1. Нормализация пробелов
        result = result.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)

        // 2. Длинное тире с неразрывной привязкой к предыдущему слову: "Война - мир" -> "Война — мир"
        result = result.replacingOccurrences(
            of: "(\\S)\\s+[-–—]\\s+(\\S)",
            with: "$1\(nbsp)— $2",
            options: .regularExpression
        )

        // 3. Привязка коротких предлогов и союзов (висячие строки)
        // Ищет слова из списка shortWordsToBind после пробела, скобки или начала строки
        let wordsPattern = "\\b(" + shortWordsToBind.joined(separator: "|") + ")\\s+"
        result = result.replacingOccurrences(
            of: wordsPattern,
            with: "$1\(nbsp)",
            options: [.regularExpression, .caseInsensitive]
        )

        // 4. Французские кавычки-ёлочки
        result = formatQuotes(result)

        return result
    }

    /// Преобразует прямые кавычки в правильные книжные парные кавычки («ёлочки» и „лапки“)
    public static func formatQuotes(_ text: String) -> String {
        var result = ""
        var inQuoteLevel = 0
        let chars = Array(text)
        var i = 0

        while i < chars.count {
            let ch = chars[i]
            if ch == "\"" || ch == "“" || ch == "”" || ch == "„" {
                let isStart = (i == 0) || (chars[i-1].isWhitespace || chars[i-1] == "(" || chars[i-1] == "[")
                if isStart {
                    inQuoteLevel += 1
                    result.append(inQuoteLevel == 1 ? "«" : "„")
                } else {
                    inQuoteLevel = max(0, inQuoteLevel - 1)
                    result.append(inQuoteLevel == 0 ? "»" : "“")
                }
            } else {
                result.append(ch)
            }
            i += 1
        }
        return result
    }
}

// MARK: - Удобные расширения для Book и String
public extension Book {
    /// Типографически безупречно отформатированное название книги
    var typographicTitle: String {
        AuthorTypographerEngine.formatTitle(title)
    }

    /// Типографически безупречно отформатированное имя автора с неразрывными инициалами
    var typographicAuthor: String {
        AuthorTypographerEngine.formatAuthor(author)
    }
}

public extension String {
    /// Применяет правила типографики для имени автора
    var typographicAuthor: String {
        AuthorTypographerEngine.formatAuthor(self)
    }

    /// Применяет правила типографики для заголовка
    var typographicTitle: String {
        AuthorTypographerEngine.formatTitle(self)
    }
}

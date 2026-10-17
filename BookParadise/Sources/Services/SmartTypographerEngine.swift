import Foundation

/// Движок автоматической типографики и нормализации цитат (Smart Typographer)
/// Превращает сырой OCR-текст или заметки в безупречный книжный текст по стандартам русского книгоиздания.
public struct SmartTypographerEngine {

    public struct TypographicOptions {
        public var replaceQuotes: Bool
        public var replaceDashes: Bool
        public var joinHyphenatedWords: Bool
        public var bindShortWords: Bool
        public var normalizeWhitespace: Bool
        public var capitalizeSentences: Bool

        public static let standard = TypographicOptions(
            replaceQuotes: true,
            replaceDashes: true,
            joinHyphenatedWords: true,
            bindShortWords: true,
            normalizeWhitespace: true,
            capitalizeSentences: true
        )
    }

    /// Нормализует текст в соответствии с правилами книжной типографики
    public static func formatText(_ input: String, options: TypographicOptions = .standard) -> String {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "" }
        var text = input

        // 1. Склейка переносов строк, вызванных версткой или OCR (сло-\nво -> слово)
        if options.joinHyphenatedWords {
            text = text.replacingOccurrences(
                of: "([А-Яа-яA-Za-z0-9])-\\s*[\\r\\n]+\\s*([А-Яа-яA-Za-z0-9])",
                with: "$1$2",
                options: .regularExpression
            )
        }

        // 2. Нормализация пробелов и переводов строк
        if options.normalizeWhitespace {
            // Замена множественных пробелов на один
            text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
            // Удаление пробелов перед знаками препинания
            text = text.replacingOccurrences(of: "\\s+([.,!?:;])", with: "$1", options: .regularExpression)
            // Удаление лишних переводов строк (>2 подряд)
            text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        }

        // 3. Замена дефисов на правильное тире
        if options.replaceDashes {
            // Тире между словами: "слово - слово" или "слово -- слово" -> "слово — слово"
            text = text.replacingOccurrences(of: "(\\s)[-–—]{1,2}(\\s)", with: "$1—$2", options: .regularExpression)
            // Числовой диапазон: "1941-1945" -> "1941–1945" (en-dash)
            text = text.replacingOccurrences(of: "(\\d)\\s*[-—]\\s*(\\d)", with: "$1–$2", options: .regularExpression)
        }

        // 4. Французские кавычки-ёлочки «...» с поддержкой немецких лапок „...“ внутри
        if options.replaceQuotes {
            text = formatQuotes(text)
        }

        // 5. Неразрывные пробелы для предлогов и союзов (висячие строки)
        if options.bindShortWords {
            // Короткие слова (1-2 буквы) привязываются неразрывным пробелом к следующему слову
            let shortWordsRegex = "(?<=[\\s(«„]|^)([а-яА-Яa-zA-Z]{1,2})\\s+"
            text = text.replacingOccurrences(of: shortWordsRegex, with: "$1\u{00A0}", options: .regularExpression)
            // Привязка тире неразрывным пробелом к предыдущему слову: "слово\u{00A0}— следующее"
            text = text.replacingOccurrences(of: "(\\S)\\s+—", with: "$1\u{00A0}—", options: .regularExpression)
        }

        // 6. Капитализация первых букв предложений
        if options.capitalizeSentences {
            text = capitalizeSentencesInText(text)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
                // Определяем: открывающая или закрывающая кавычка
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

    /// Восстанавливает заглавные буквы после точек, вопросительных и восклицательных знаков
    public static func capitalizeSentencesInText(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        var result = ""
        var capitalizeNext = true

        for ch in text {
            if capitalizeNext && ch.isLetter {
                result.append(ch.uppercased())
                capitalizeNext = false
            } else {
                result.append(ch)
                if ch == "." || ch == "!" || ch == "?" || ch == "\n" {
                    capitalizeNext = true
                }
            }
        }
        return result
    }
}

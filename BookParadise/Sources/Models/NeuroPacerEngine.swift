import Foundation

/// Нейро-пейсер и движок управления зрительным фокусом (Bionic Reading & RSVP Engine)
/// Разработан на основе исследований саккадических движений глаз и точки оптимального распознавания (ORP).
public struct NeuroPacerEngine {

    public enum FixationStrength: Double, CaseIterable, Identifiable {
        case light = 0.30     // 30% слова — мягкий акцент
        case balanced = 0.45  // 45% слова — классический баланс
        case deep = 0.60      // 60% слова — максимальная фиксация (для уставших глаз или дислексии)

        public var id: Double { rawValue }

        public var title: String {
            switch self {
            case .light: return "Мягкий (30%)"
            case .balanced: return "Оптимальный (45%)"
            case .deep: return "Глубокий (60%)"
            }
        }
    }

    public struct TokenizedWord: Equatable {
        public let fullWord: String
        public let boldPrefix: String
        public let regularSuffix: String
        public let optimalRecognitionIndex: Int // Индекс ORP для скорочтения
        public let durationMultiplier: Double   // Множитель задержки (для пунктуации и длинных слов)

        public init(
            fullWord: String,
            boldPrefix: String,
            regularSuffix: String,
            optimalRecognitionIndex: Int,
            durationMultiplier: Double = 1.0
        ) {
            self.fullWord = fullWord
            self.boldPrefix = boldPrefix
            self.regularSuffix = regularSuffix
            self.optimalRecognitionIndex = optimalRecognitionIndex
            self.durationMultiplier = durationMultiplier
        }
    }

    /// Вычисляет оптимальную точку распознавания слова (Optimal Recognition Point / ORP)
    /// В этой точке глаз воспринимает слово целиком без повторных саккад.
    public static func calculateORP(wordLength: Int) -> Int {
        guard wordLength > 0 else { return 0 }
        switch wordLength {
        case 1: return 0
        case 2...5: return 1
        case 6...9: return 2
        case 10...13: return 3
        default: return 4
        }
    }

    /// Токенизирует отдельное слово с разделением на фиксированную и остаточную части
    public static func processWord(_ rawWord: String, strength: FixationStrength = .balanced) -> TokenizedWord {
        guard !rawWord.isEmpty else {
            return TokenizedWord(fullWord: "", boldPrefix: "", regularSuffix: "", optimalRecognitionIndex: 0)
        }

        // Отделяем хвостовую пунктуацию для корректного выделения
        var cleanLetters = ""
        var trailingPunctuation = ""
        var isTrailing = false

        for ch in rawWord {
            if ch.isLetter || ch.isNumber {
                if isTrailing {
                    // Если после пунктуации снова буква, сбрасываем флаг
                    cleanLetters.append(trailingPunctuation)
                    trailingPunctuation = ""
                    isTrailing = false
                }
                cleanLetters.append(ch)
            } else {
                isTrailing = true
                trailingPunctuation.append(ch)
            }
        }

        let length = cleanLetters.count
        guard length > 0 else {
            return TokenizedWord(
                fullWord: rawWord,
                boldPrefix: "",
                regularSuffix: rawWord,
                optimalRecognitionIndex: 0
            )
        }

        // Расчёт количества жирных букв по выбранной силе фиксации
        let boldCount: Int
        if length <= 2 {
            boldCount = 1
        } else if length <= 4 {
            boldCount = max(1, Int(round(Double(length) * strength.rawValue)))
        } else {
            boldCount = min(length, max(2, Int(ceil(Double(length) * strength.rawValue))))
        }

        let prefixEndIndex = cleanLetters.index(cleanLetters.startIndex, offsetBy: boldCount)
        let boldPrefix = String(cleanLetters[..<prefixEndIndex])
        let regularSuffix = String(cleanLetters[prefixEndIndex...]) + trailingPunctuation

        // Вычисление ORP
        let orp = calculateORP(wordLength: length)

        // Коэффициент времени чтения слова
        var multiplier: Double = 1.0
        if rawWord.hasSuffix(".") || rawWord.hasSuffix("!") || rawWord.hasSuffix("?") {
            multiplier = 2.2 // Пауза в конце предложения
        } else if rawWord.hasSuffix(",") || rawWord.hasSuffix(";") || rawWord.hasSuffix(":") || rawWord.hasSuffix("—") {
            multiplier = 1.6 // Пауза в середине предложения
        } else if length > 9 {
            multiplier = 1.3 // Длинное слово
        }

        return TokenizedWord(
            fullWord: rawWord,
            boldPrefix: boldPrefix,
            regularSuffix: regularSuffix,
            optimalRecognitionIndex: orp,
            durationMultiplier: multiplier
        )
    }

    /// Рассчитывает интервал показа одного слова для скорочтения в миллисекундах по целевому WPM
    public static func millisecondInterval(for wpm: Int, multiplier: Double = 1.0) -> Double {
        let safeWpm = max(60, min(1200, wpm))
        let baseMs = (60.0 / Double(safeWpm)) * 1000.0
        return baseMs * multiplier
    }
}

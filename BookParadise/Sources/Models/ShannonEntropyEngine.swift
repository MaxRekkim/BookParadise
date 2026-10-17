import Foundation
import SwiftUI
import Combine

// MARK: - Cognitive Density Band
public enum CognitiveDensityBand: String, CaseIterable, Identifiable, Codable {
    case airy = "Воздушный слог"
    case narrative = "Классическая проза"
    case academic = "Академический компендиум"
    case dense = "Герметическая глубина"
    
    public var id: String { rawValue }
    
    public var subtitle: String {
        switch self {
        case .airy:
            return "Быстрое восприятие, динамичное повествование и живой диалог"
        case .narrative:
            return "Гармоничный баланс сюжетной динамики, образов и мысли"
        case .academic:
            return "Высокая концентрация понятий, академическая и критическая мысль"
        case .dense:
            return "Предельная информационная плотность, полифония смыслов и метафизика"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .airy:
            return Color(red: 0.35, green: 0.70, blue: 0.90)
        case .narrative:
            return Color(red: 0.45, green: 0.78, blue: 0.50)
        case .academic:
            return Color(red: 0.92, green: 0.65, blue: 0.25)
        case .dense:
            return Color(red: 0.88, green: 0.38, blue: 0.45)
        }
    }
    
    public var icon: String {
        switch self {
        case .airy: return "wind"
        case .narrative: return "book.closed"
        case .academic: return "graduationcap"
        case .dense: return "atom"
        }
    }
}

// MARK: - Entropy Analysis Result
public struct EntropyAnalysisResult: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public let totalTokens: Int
    public let uniqueTypes: Int
    public let typeTokenRatio: Double
    public let shannonEntropyBits: Double
    public let normalizedEntropy: Double // 0.0 ... 1.0
    public let averageWordLength: Double
    public let averageSentenceLength: Double
    public let colemanLiauIndex: Double
    public let densityBand: CognitiveDensityBand
    public let recommendedPacingWPM: Int
    public let topKeywords: [String]
    
    public init(
        totalTokens: Int,
        uniqueTypes: Int,
        typeTokenRatio: Double,
        shannonEntropyBits: Double,
        normalizedEntropy: Double,
        averageWordLength: Double,
        averageSentenceLength: Double,
        colemanLiauIndex: Double,
        densityBand: CognitiveDensityBand,
        recommendedPacingWPM: Int,
        topKeywords: [String]
    ) {
        self.totalTokens = totalTokens
        self.uniqueTypes = uniqueTypes
        self.typeTokenRatio = typeTokenRatio
        self.shannonEntropyBits = shannonEntropyBits
        self.normalizedEntropy = normalizedEntropy
        self.averageWordLength = averageWordLength
        self.averageSentenceLength = averageSentenceLength
        self.colemanLiauIndex = colemanLiauIndex
        self.densityBand = densityBand
        self.recommendedPacingWPM = recommendedPacingWPM
        self.topKeywords = topKeywords
    }
    
    public static var empty: EntropyAnalysisResult {
        EntropyAnalysisResult(
            totalTokens: 0,
            uniqueTypes: 0,
            typeTokenRatio: 0.0,
            shannonEntropyBits: 0.0,
            normalizedEntropy: 0.0,
            averageWordLength: 0.0,
            averageSentenceLength: 0.0,
            colemanLiauIndex: 0.0,
            densityBand: .airy,
            recommendedPacingWPM: 250,
            topKeywords: []
        )
    }
}

// MARK: - Shannon Entropy Engine
public final class ShannonEntropyEngine: ObservableObject {
    public static let shared = ShannonEntropyEngine()
    
    @Published public private(set) var currentResult: EntropyAnalysisResult = .empty
    
    private init() {}
    
    // MARK: - Core Analysis
    public func analyze(text: String) -> EntropyAnalysisResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            let empty = EntropyAnalysisResult.empty
            DispatchQueue.main.async { self.currentResult = empty }
            return empty
        }
        
        // 1. Извлечение токенов (слов)
        let tokenPattern = "\\b[\\p{L}\\p{N}-]+\\b"
        guard let regex = try? NSRegularExpression(pattern: tokenPattern, options: []) else {
            return .empty
        }
        
        let nsString = trimmed as NSString
        let matches = regex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))
        
        let words = matches.map { nsString.substring(with: $0.range).lowercased() }
        guard !words.isEmpty else { return .empty }
        
        let totalTokens = words.count
        
        // 2. Расчет частотного распределения
        var freqMap: [String: Int] = [:]
        for w in words {
            freqMap[w, default: 0] += 1
        }
        
        let uniqueTypes = freqMap.count
        let typeTokenRatio = Double(uniqueTypes) / Double(totalTokens)
        
        // 3. Энтропия Шеннона: H(X) = - Σ P(x) * log2(P(x))
        let nDouble = Double(totalTokens)
        var shannonBits: Double = 0.0
        for count in freqMap.values {
            let p = Double(count) / nDouble
            if p > 0 {
                shannonBits -= p * (log(p) / log(2.0))
            }
        }
        
        // Нормализованная энтропия H_norm = H(X) / log2(N)
        let maxTheoreticalEntropy = log(max(2.0, nDouble)) / log(2.0)
        let normalizedEntropy = min(1.0, max(0.0, shannonBits / maxTheoreticalEntropy))
        
        // 4. Длина слов и предложений
        let totalLetters = words.reduce(0) { $0 + $1.count }
        let avgWordLength = Double(totalLetters) / Double(totalTokens)
        
        let sentenceDelimiters = CharacterSet(charactersIn: ".!?;…")
        let sentenceCount = max(1, trimmed.components(separatedBy: sentenceDelimiters).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count)
        let avgSentenceLength = Double(totalTokens) / Double(sentenceCount)
        
        // 5. Индекс удобочитаемости Колман-Лиау (CLI)
        // L = (букв / слов) * 100, S = (предложений / слов) * 100
        let L = (Double(totalLetters) / Double(totalTokens)) * 100.0
        let S = (Double(sentenceCount) / Double(totalTokens)) * 100.0
        let cli = 0.0588 * L - 0.296 * S - 15.8
        
        // 6. Определение когнитивного диапазона
        let band: CognitiveDensityBand
        if normalizedEntropy >= 0.85 || typeTokenRatio >= 0.75 {
            band = .dense
        } else if normalizedEntropy >= 0.70 || typeTokenRatio >= 0.60 {
            band = .academic
        } else if normalizedEntropy >= 0.55 || typeTokenRatio >= 0.45 {
            band = .narrative
        } else {
            band = .airy
        }
        
        // 7. Рекомендуемая скорость чтения (WPM)
        let recommendedWPM: Int
        switch band {
        case .dense: recommendedWPM = 160
        case .academic: recommendedWPM = 210
        case .narrative: recommendedWPM = 270
        case .airy: recommendedWPM = 330
        }
        
        // 8. Ключевые термины (наиболее редкие и весомые слова > 4 букв)
        let stopWords: Set<String> = [
            "что", "как", "это", "для", "или", "все", "его", "она", "они", "был", "были", "была",
            "так", "уже", "при", "еще", "тот", "того", "том", "где", "кто", "чем", "под", "над",
            "the", "and", "that", "this", "with", "from", "have", "they", "will", "would", "their"
        ]
        
        let topKeywords = freqMap
            .filter { $0.key.count > 3 && !stopWords.contains($0.key) }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        let result = EntropyAnalysisResult(
            totalTokens: totalTokens,
            uniqueTypes: uniqueTypes,
            typeTokenRatio: (typeTokenRatio * 100).rounded() / 100,
            shannonEntropyBits: (shannonBits * 100).rounded() / 100,
            normalizedEntropy: (normalizedEntropy * 100).rounded() / 100,
            averageWordLength: (avgWordLength * 10).rounded() / 10,
            averageSentenceLength: (avgSentenceLength * 10).rounded() / 10,
            colemanLiauIndex: max(1.0, (cli * 10).rounded() / 10),
            densityBand: band,
            recommendedPacingWPM: recommendedWPM,
            topKeywords: topKeywords
        )
        
        DispatchQueue.main.async {
            self.currentResult = result
        }
        
        return result
    }
}

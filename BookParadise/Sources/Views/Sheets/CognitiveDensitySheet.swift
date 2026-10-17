import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct CognitiveDensitySheet: View {
    public let result: EntropyAnalysisResult
    
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public init(result: EntropyAnalysisResult) {
        self.result = result
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Hero Cognitive Band Card
                    heroBandCard
                    
                    // MARK: - Key Metrics Grid
                    metricsGrid
                    
                    // MARK: - Top Lexical Footprint
                    if !result.topKeywords.isEmpty {
                        lexicalFootprintSection
                    }
                    
                    // MARK: - Cognitive Pacing Advisory
                    pacingAdvisorySection
                }
                .padding()
            }
            .navigationTitle("Когнитивная плотность")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryAccent)
                }
            }
        }
    }
    
    // MARK: - Hero Band Card
    private var heroBandCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(result.densityBand.badgeColor.opacity(0.18))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: result.densityBand.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(result.densityBand.badgeColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.densityBand.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    
                    Text(result.densityBand.subtitle)
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            // Normalized Entropy Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Нормализованная энтропия H(X)")
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text("\(Int(result.normalizedEntropy * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(result.densityBand.badgeColor)
                }
                
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [theme.primaryAccent, result.densityBand.badgeColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, g.size.width * CGFloat(result.normalizedEntropy)), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricTile(
                title: "Энтропия Шеннона",
                value: "\(result.shannonEntropyBits) бит",
                caption: "Информационная мера",
                icon: "chart.bar.xaxis"
            )
            
            metricTile(
                title: "Лексическое богатство",
                value: "\(Int(result.typeTokenRatio * 100))% TTR",
                caption: "\(result.uniqueTypes) из \(result.totalTokens) слов",
                icon: "character.book.closed"
            )
            
            metricTile(
                title: "Индекс Колман-Лиау",
                value: "\(result.colemanLiauIndex)",
                caption: "Уровень сложности",
                icon: "chart.line.uptrend.xyaxis"
            )
            
            metricTile(
                title: "Темп восприятия",
                value: "\(result.recommendedPacingWPM) сл/мин",
                caption: "Оптимальный ритм",
                icon: "metronome"
            )
        }
    }
    
    private func metricTile(title: String, value: String, caption: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(theme.primaryAccent)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(Color(UIColor.label))
            
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            Text(caption)
                .font(.system(size: 10))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Top Lexical Footprint
    private var lexicalFootprintSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("КЛЮЧЕВЫЕ ПОНЯТИЯ РАЗВОРОТА")
                .font(.caption2)
                .fontWeight(.heavy)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .tracking(1.2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(result.topKeywords, id: \.self) { word in
                        Text(word)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundColor(Color(UIColor.label))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(UIColor.tertiarySystemGroupedBackground))
                            )
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Pacing Advisory
    private var pacingAdvisorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.25))
                    .font(.subheadline)
                
                Text("Совет библиофила")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Text(pacingAdviceText)
                .font(.system(size: 13, weight: .regular, design: .serif))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var pacingAdviceText: String {
        switch result.densityBand {
        case .dense:
            return "Текст обладает предельной энтропией Шеннона: почти каждое слово несет уникальный смысл. Для кристального понимания рекомендуется читать вдумчиво, фиксируя маргиналии на полях и делая короткие паузы между абзацами."
        case .academic:
            return "Высокая терминологическая плотность требует устойчивого внимания. Оптимально читать сессиями по 25-30 минут с включением бинаурального фокуса или звука камина."
        case .narrative:
            return "Превосходный баланс художественной ткани и динамики. Текст читается естественно и погружает в классический поток без излишнего утомления зрительного аппарата."
        case .airy:
            return "Легкий диалоговый слог. Прекрасно подходит для вечернего отдыха, быстрого погружения и плавного переключения внимания."
        }
    }
}

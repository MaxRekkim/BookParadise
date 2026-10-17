import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct QuoteSemanticClusterView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var quotes: [SemanticQuote]
    @State private var dialecticPairs: [DialecticQuotePair]
    @State private var selectedMotif: LiteraryMotifCategory? = nil
    @State private var showDialecticsOnly: Bool = false
    
    public init(
        quotes: [SemanticQuote] = QuoteSemanticClusterEngine.sampleQuotes,
        dialecticPairs: [DialecticQuotePair] = QuoteSemanticClusterEngine.sampleDialecticPairs
    ) {
        _quotes = State(initialValue: quotes)
        _dialecticPairs = State(initialValue: dialecticPairs)
    }
    
    private var clusters: [SemanticMotifCluster] {
        QuoteSemanticClusterEngine.clusterQuotes(quotes)
    }
    
    private var filteredQuotes: [SemanticQuote] {
        if let motif = selectedMotif {
            return quotes.filter { $0.motif == motif }
        }
        return quotes
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Tab Toggle: Clusters vs Dialectics
            Picker("Режим", selection: $showDialecticsOnly.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
                Text("Кластеры мотивов").tag(false)
                Text("Диалектический диалог").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if showDialecticsOnly {
                // Dialectic Pairs View
                VStack(spacing: 12) {
                    ForEach(dialecticPairs) { pair in
                        dialecticPairCard(pair: pair)
                    }
                }
            } else {
                // Motif Clusters View
                VStack(spacing: 12) {
                    motifFilterChips
                    
                    VStack(spacing: 10) {
                        ForEach(filteredQuotes) { quote in
                            quoteCard(quote: quote)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("СЕМАНТИЧЕСКИЙ РЕЗОНАНС")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("\(quotes.count) ЦИТАТ")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                }
                
                Text("Кросс-книжные мотивы")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "quote.bubble.rtl.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Motif Filter Chips
    private var motifFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                motifChip(title: "Все", isSelected: selectedMotif == nil) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedMotif = nil
                }
                
                ForEach(LiteraryMotifCategory.allCases, id: \.self) { motif in
                    let count = quotes.filter { $0.motif == motif }.count
                    if count > 0 {
                        motifChip(
                            title: motif.rawValue,
                            icon: motif.iconName,
                            badge: "\(count)",
                            isSelected: selectedMotif == motif
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedMotif = (selectedMotif == motif) ? nil : motif
                        }
                    }
                }
            }
        }
    }
    
    private func motifChip(title: String, icon: String? = nil, badge: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 8, weight: .heavy))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2)))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? theme.primaryAccent : Color(UIColor.tertiarySystemGroupedBackground))
            )
            .foregroundColor(isSelected ? .white : Color(UIColor.secondaryLabel))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Quote Card
    private func quoteCard(quote: SemanticQuote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: quote.motif.iconName)
                    .font(.caption2)
                    .foregroundColor(quote.motif.accentColor)
                
                Text(quote.motif.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(quote.motif.accentColor)
                
                Spacer()
                
                Text("с. \(quote.pageNumber)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            Text("«\(quote.text)»")
                .font(.subheadline)
                .fontWeight(.medium)
                .italic()
                .foregroundColor(Color(UIColor.label))
                .lineSpacing(3)
            
            HStack {
                Text(quote.author)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                
                Text("— \(quote.bookTitle)")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = "«\(quote.text)» — \(quote.author), \(quote.bookTitle)"
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.7))
        )
    }
    
    // MARK: - Dialectic Pair Card
    private func dialecticPairCard(pair: DialecticQuotePair) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.caption2)
                        .foregroundColor(pair.motif.accentColor)
                    
                    Text("ДИАЛЕКТИЧЕСКИЙ СПОР")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(pair.motif.accentColor)
                }
                
                Spacer()
                
                Text(pair.motif.rawValue)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            // Side-by-side or stacked Thesis vs Antithesis
            VStack(spacing: 8) {
                // Thesis
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("ТЕЗИС: \(pair.thesis.author)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.blue)
                        Spacer()
                        Text("«\(pair.thesis.bookTitle)»")
                            .font(.system(size: 8))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    Text("«\(pair.thesis.text)»")
                        .font(.caption)
                        .italic()
                        .foregroundColor(Color(UIColor.label))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.blue.opacity(0.08))
                )
                
                // Antithesis
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("АНТИТЕЗИС: \(pair.antithesis.author)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.purple)
                        Spacer()
                        Text("«\(pair.antithesis.bookTitle)»")
                            .font(.system(size: 8))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    Text("«\(pair.antithesis.text)»")
                        .font(.caption)
                        .italic()
                        .foregroundColor(Color(UIColor.label))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.purple.opacity(0.08))
                )
            }
            
            // Synthesis
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(theme.primaryAccent)
                
                Text(pair.synthesisCommentary)
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineSpacing(2)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.primaryAccent.opacity(0.06))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.9))
        )
    }
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct AuthorInfluenceMatrixView: View {
    @State public var matrix: AuthorInfluenceMatrix
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedAuthorId: UUID? = nil
    
    public init(matrix: AuthorInfluenceMatrix = .sampleBulgakovGenealogy) {
        _matrix = State(initialValue: matrix)
    }
    
    private var centralAuthorNode: AuthorInfluenceNode? {
        matrix.nodes.first { $0.name == matrix.centralAuthorName }
    }
    
    private var activeSelectedNode: AuthorInfluenceNode? {
        if let id = selectedAuthorId {
            return matrix.node(with: id)
        }
        return centralAuthorNode
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Central Author & Lineage Layout
            if let central = centralAuthorNode {
                genealogyTreeSection(central: central)
            }
            
            // Detailed Inspector Card for Selected Author
            if let active = activeSelectedNode, let central = centralAuthorNode {
                authorInspectorCard(active: active, central: central)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("ГЕНЕАЛОГИЯ ВДОХНОВЕНИЯ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("ВЕКТОРНЫЙ АНАЛИЗ")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.indigo))
                }
                
                Text(matrix.centralAuthorName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Genealogy Tree Section
    private func genealogyTreeSection(central: AuthorInfluenceNode) -> some View {
        let predecessors = matrix.predecessors(for: central.id)
        let successors = matrix.successors(for: central.id)
        
        return VStack(spacing: 12) {
            // Predecessors / Inspirations
            if !predecessors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ИСТОКИ И ВДОХНОВИТЕЛИ")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(predecessors, id: \.author.id) { item in
                                authorPill(node: item.author, link: item.link, central: central)
                            }
                        }
                    }
                }
            }
            
            // Central Node Pill
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(theme.primaryAccent)
                        Text(central.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor.label))
                    }
                    Text(central.flagshipWork)
                        .font(.caption2)
                        .italic()
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.primaryAccent.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(theme.primaryAccent.opacity(0.4), lineWidth: 1.5)
                        )
                )
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedAuthorId = central.id
                }
            }
            
            // Successors / Literary Echoes
            if !successors.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ПРЕЕМНИКИ И ТЕМАТИЧЕСКИЕ ЭХО")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(successors, id: \.author.id) { item in
                                authorPill(node: item.author, link: item.link, central: central)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Author Mini-Pill
    private func authorPill(node: AuthorInfluenceNode, link: AuthorInfluenceLink, central: AuthorInfluenceNode) -> some View {
        let similarity = Int(round(node.vector.cosineSimilarity(to: central.vector) * 100))
        let isSelected = (selectedAuthorId == node.id)
        
        return Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedAuthorId = node.id
            }
        }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: link.type.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(link.type.accentColor)
                    
                    Text("\(similarity)% схожесть")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(link.type.accentColor)
                }
                
                Text(node.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)
                
                Text(node.eraString)
                    .font(.system(size: 9))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? link.type.accentColor.opacity(0.18) : Color(UIColor.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? link.type.accentColor : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Author Detail Inspector
    private func authorInspectorCard(active: AuthorInfluenceNode, central: AuthorInfluenceNode) -> some View {
        let sim = active.vector.cosineSimilarity(to: central.vector)
        let simPct = Int(round(sim * 100))
        
        // Find link if between active and central
        let linkContext = matrix.links.first {
            ($0.sourceAuthorId == active.id && $0.targetAuthorId == central.id) ||
            ($0.sourceAuthorId == central.id && $0.targetAuthorId == active.id)
        }
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(active.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("\(active.keyMovement) • \(active.flagshipWork)")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                if active.id != central.id {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(simPct)%")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(theme.primaryAccent)
                        Text("косинусное сходство")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                }
            }
            
            if let link = linkContext {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundColor(link.type.accentColor)
                    
                    Text(link.historicalContext)
                        .font(.caption)
                        .italic()
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(link.type.accentColor.opacity(0.08))
                )
            }
            
            // Stylistic Dimension Bars
            VStack(spacing: 5) {
                dimensionBar(title: "Экзистенциальная глубина", value: active.vector.existentialDepth, color: .purple)
                dimensionBar(title: "Психологический реализм", value: active.vector.psychologicalRealism, color: .blue)
                dimensionBar(title: "Магический мистицизм", value: active.vector.magicalMysticism, color: .orange)
                dimensionBar(title: "Социальная сатира", value: active.vector.socialSatire, color: .red)
                dimensionBar(title: "Трагическая возвышенность", value: active.vector.tragicSublimity, color: .indigo)
                dimensionBar(title: "Лиричность & Ритм", value: active.vector.lyricalRhythm, color: .green)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.8))
        )
    }
    
    private func dimensionBar(title: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .frame(width: 140, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value))
                }
            }
            .frame(height: 5)
            
            Text("\(Int(value * 100))%")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color(UIColor.label))
                .frame(width: 32, alignment: .trailing)
        }
    }
}

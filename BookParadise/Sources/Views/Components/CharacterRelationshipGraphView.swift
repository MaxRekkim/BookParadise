import SwiftUI
import Darwin
#if canImport(UIKit)
import UIKit
#endif

public struct CharacterRelationshipGraphView: View {
    @State public var graph: BookCharacterGraph
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedNodeId: UUID? = nil
    @State private var isSimulating: Bool = true
    @State private var draggedNodeId: UUID? = nil
    
    public init(graph: BookCharacterGraph = .sampleMasterAndMargarita) {
        _graph = State(initialValue: graph)
    }
    
    private var selectedNode: CharacterNode? {
        graph.nodes.first { $0.id == selectedNodeId }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            headerSection
            
            // 2D Граф связей Canvas
            ZStack {
                GeometryReader { geo in
                    let size = geo.size
                    
                    // Фон графа с координатной микросеткой
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                    
                    // Отрисовка рёбер графа
                    ForEach(graph.edges) { edge in
                        if let s = graph.nodes.first(where: { $0.id == edge.sourceId }),
                           let t = graph.nodes.first(where: { $0.id == edge.targetId }) {
                            Path { path in
                                path.move(to: CGPoint(x: s.x, y: s.y))
                                path.addLine(to: CGPoint(x: t.x, y: t.y))
                            }
                            .stroke(
                                edge.type.edgeColor.opacity(0.65),
                                style: StrokeStyle(lineWidth: 2, dash: edge.type == .betrayal ? [6, 4] : [])
                            )
                        }
                    }
                    
                    // Отрисовка узлов персонажей
                    ForEach(graph.nodes) { node in
                        nodeView(node: node, in: size)
                    }
                }
                .frame(height: 290)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            }
            
            // Инспектор выбранного персонажа
            if let node = selectedNode {
                nodeInspectorCard(node: node)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
                    Text("ГРАФ ПЕРСОНАЖЕЙ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("\(graph.nodes.count) ГЕРОЕВ")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(theme.primaryAccent))
                }
                
                Text("«\(graph.bookTitle)»")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    ForceDirectedGraphEngine.stepSimulation(
                        nodes: &graph.nodes,
                        edges: graph.edges,
                        width: 320,
                        height: 280
                    )
                }
                HapticManager.shared.lightTap()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Баланс")
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryAccent)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(theme.primaryAccent.opacity(0.12))
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Node View
    private func nodeView(node: CharacterNode, in size: CGSize) -> some View {
        let isSelected = selectedNodeId == node.id
        
        return VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(node.role.accentColor.opacity(isSelected ? 0.35 : 0.18))
                    .frame(width: 38, height: 38)
                
                Circle()
                    .stroke(isSelected ? node.role.accentColor : Color.clear, lineWidth: 2)
                    .frame(width: 42, height: 42)
                
                Text(node.avatarInitials)
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundColor(node.role.accentColor)
                
                Image(systemName: node.role.iconName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Circle().fill(node.role.accentColor))
                    .offset(x: 13, y: 13)
            }
            
            Text(node.name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
                .lineLimit(1)
        }
        .position(x: CGFloat(node.x), y: CGFloat(node.y))
        .onTapGesture {
            selectedNodeId = (selectedNodeId == node.id) ? nil : node.id
            HapticManager.shared.lightTap()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if let idx = graph.nodes.firstIndex(where: { $0.id == node.id }) {
                        graph.nodes[idx].x = Double(value.location.x)
                        graph.nodes[idx].y = Double(value.location.y)
                    }
                }
        )
    }
    
    // MARK: - Node Inspector
    private func nodeInspectorCard(node: CharacterNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(node.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if let alias = node.alias {
                    Text("(\(alias))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(node.role.rawValue)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(node.role.accentColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(node.role.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            let connectedEdges = graph.edges.filter { $0.sourceId == node.id || $0.targetId == node.id }
            if !connectedEdges.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(connectedEdges) { edge in
                        let otherId = (edge.sourceId == node.id) ? edge.targetId : edge.sourceId
                        if let other = graph.nodes.first(where: { $0.id == otherId }) {
                            HStack(spacing: 6) {
                                Circle().fill(edge.type.edgeColor).frame(width: 6, height: 6)
                                Text("\(edge.type.rawValue):")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(edge.type.edgeColor)
                                Text(other.name)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                if let notes = edge.notes {
                                    Text("— \(notes)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

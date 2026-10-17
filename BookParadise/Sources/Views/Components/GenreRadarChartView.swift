import SwiftUI

// MARK: - Виджет интерактивного жанрового радара (Spider Chart)
public struct GenreRadarChartView: View {
    public let books: [Book]
    
    @State private var selectedPoint: GenreRadarPoint? = nil
    @State private var animateIn = false
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(books: [Book]) {
        self.books = books
    }
    
    private var report: GenreRadarReport {
        GenreRadarEngine.generateReport(from: books)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок карточки с архетипом
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(report.archetype.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: report.archetype.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(report.archetype.color)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Радар разнообразия")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(report.shannonEntropy * 100))%")
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(report.archetype.color.opacity(0.2))
                            .foregroundColor(report.archetype.color)
                            .clipShape(Capsule())
                    }
                    
                    Text(report.archetype.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            Text(report.archetype.description)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Сама паутинная диаграмма
            ZStack {
                RadarBackgroundGrid(sides: report.points.count)
                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    .frame(height: 240)
                
                RadarDataPolygon(
                    points: report.points,
                    scale: animateIn ? 1.0 : 0.0
                )
                .fill(
                    LinearGradient(
                        colors: [
                            report.archetype.color.opacity(0.50),
                            report.archetype.color.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 240)
                
                RadarDataPolygon(
                    points: report.points,
                    scale: animateIn ? 1.0 : 0.0
                )
                .stroke(report.archetype.color, lineWidth: 2)
                .frame(height: 240)
                
                // Вершины с интерактивным тапом
                RadarVerticesView(
                    points: report.points,
                    color: report.archetype.color,
                    scale: animateIn ? 1.0 : 0.0,
                    selectedPoint: $selectedPoint
                )
                .frame(height: 240)
            }
            .padding(.vertical, 10)
            
            // Всплывающая плашка с деталями выбранного жанра
            if let selected = selectedPoint {
                HStack(spacing: 10) {
                    Image(systemName: selected.genre.iconName)
                        .foregroundColor(selected.genre.accentColor)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selected.genre.rawValue)
                            .font(.subheadline)
                            .bold()
                        Text("\(selected.count) книг (\(String(format: "%.1f", selected.percentage))% библиотеки)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPoint = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Коснитесь любой вершины радара для деталей жанра")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Фоновая концентрическая сетка радара
struct RadarBackgroundGrid: Shape {
    let sides: Int
    let levels: Int = 4 // 25%, 50%, 75%, 100%
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard sides >= 3 else { return path }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0 * 0.82
        let angleStep = (2 * Double.pi) / Double(sides)
        
        // Концентрические полигоны
        for level in 1...levels {
            let currentRadius = radius * (Double(level) / Double(levels))
            for i in 0..<sides {
                let angle = Double(i) * angleStep - Double.pi / 2
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle) * currentRadius),
                    y: center.y + CGFloat(sin(angle) * currentRadius)
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
        
        // Лучевые оси из центра
        for i in 0..<sides {
            let angle = Double(i) * angleStep - Double.pi / 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle) * radius),
                y: center.y + CGFloat(sin(angle) * radius)
            )
            path.move(to: center)
            path.addLine(to: point)
        }
        
        return path
    }
}

// MARK: - Полигон данных пользователя
struct RadarDataPolygon: Shape {
    let points: [GenreRadarPoint]
    var scale: Double
    
    var animatableData: Double {
        get { scale }
        set { scale = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = points.count
        guard count >= 3 else { return path }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2.0 * 0.82
        let angleStep = (2 * Double.pi) / Double(count)
        
        var isFirst = true
        for (i, pt) in points.enumerated() {
            let angle = Double(i) * angleStep - Double.pi / 2
            // Минимальный радиус 0.08 для видимости полигона
            let effectiveRadius = (0.08 + pt.normalizedRadius * 0.92) * maxRadius * scale
            let currentPoint = CGPoint(
                x: center.x + CGFloat(cos(angle) * effectiveRadius),
                y: center.y + CGFloat(sin(angle) * effectiveRadius)
            )
            
            if isFirst {
                path.move(to: currentPoint)
                isFirst = false
            } else {
                path.addLine(to: currentPoint)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Вершины и метки жанров
struct RadarVerticesView: View {
    let points: [GenreRadarPoint]
    let color: Color
    let scale: Double
    @Binding var selectedPoint: GenreRadarPoint?
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
            let maxRadius = min(geo.size.width, geo.size.height) / 2.0 * 0.82
            let count = points.count
            let angleStep = (2 * Double.pi) / Double(count)
            
            ForEach(0..<count, id: \.self) { i in
                let pt = points[i]
                let angle = Double(i) * angleStep - Double.pi / 2
                let effectiveRadius = (0.08 + pt.normalizedRadius * 0.92) * maxRadius * scale
                let pointPos = CGPoint(
                    x: center.x + CGFloat(cos(angle) * effectiveRadius),
                    y: center.y + CGFloat(sin(angle) * effectiveRadius)
                )
                
                // Внешняя метка иконки жанра
                let labelRadius = maxRadius + 16
                let labelPos = CGPoint(
                    x: center.x + CGFloat(cos(angle) * labelRadius),
                    y: center.y + CGFloat(sin(angle) * labelRadius)
                )
                
                ZStack {
                    // Иконка жанра на краю
                    Image(systemName: pt.genre.iconName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(pt.genre.accentColor)
                        .position(labelPos)
                    
                    // Интерактивная светящаяся точка
                    Circle()
                        .fill(selectedPoint?.id == pt.id ? Color.white : color)
                        .frame(width: selectedPoint?.id == pt.id ? 10 : 7, height: selectedPoint?.id == pt.id ? 10 : 7)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: selectedPoint?.id == pt.id ? 3 : 1)
                        )
                        .shadow(color: color.opacity(0.4), radius: 3)
                        .position(pointPos)
                        .onTapGesture {
                            #if canImport(UIKit)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            #endif
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                if selectedPoint?.id == pt.id {
                                    selectedPoint = nil
                                } else {
                                    selectedPoint = pt
                                }
                            }
                        }
                }
            }
        }
    }
}

import SwiftUI
import Charts

public enum VelocityPeriod: String, CaseIterable, Identifiable {
    case days7 = "7Д"
    case days30 = "30Д"
    case months6 = "6М"
    case months12 = "12М"
    
    public var id: String { rawValue }
}

public struct ReadingDataPoint: Identifiable {
    public let id = UUID()
    public let label: String
    public let pages: Int
    public let index: Int
}

public struct ReadingVelocityChartView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @State private var selectedPeriod: VelocityPeriod = .days30
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    private var dataPoints: [ReadingDataPoint] {
        let history = sessionManager.sessionHistory
        let cal = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .days7:
            return (0..<7).map { i in
                let targetDate = cal.date(byAdding: .day, value: (i - 6), to: now) ?? now
                let pages = history.filter { cal.isDate($0.date, inSameDayAs: targetDate) }
                    .reduce(0) { $0 + $1.pagesRead }
                let weekday = cal.component(.weekday, from: targetDate)
                let name = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"][weekday - 1]
                return ReadingDataPoint(label: name, pages: pages, index: i)
            }
            
        case .days30:
            return (0..<6).map { i in
                let startDay = cal.date(byAdding: .day, value: (i - 5) * 5, to: now) ?? now
                var pages = 0
                for d in 0..<5 {
                    if let check = cal.date(byAdding: .day, value: d, to: startDay) {
                        pages += history.filter { cal.isDate($0.date, inSameDayAs: check) }.reduce(0) { $0 + $1.pagesRead }
                    }
                }
                let dayNum = cal.component(.day, from: startDay)
                return ReadingDataPoint(label: "\(dayNum)", pages: pages, index: i)
            }
            
        case .months6:
            let monthNames = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
            return (0..<6).map { i in
                let targetDate = cal.date(byAdding: .month, value: (i - 5), to: now) ?? now
                let m = cal.component(.month, from: targetDate)
                let y = cal.component(.year, from: targetDate)
                let pages = history.filter {
                    cal.component(.month, from: $0.date) == m && cal.component(.year, from: $0.date) == y
                }.reduce(0) { $0 + $1.pagesRead }
                return ReadingDataPoint(label: monthNames[m - 1], pages: pages, index: i)
            }
            
        case .months12:
            let monthNames = ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"]
            return (0..<12).map { i in
                let targetDate = cal.date(byAdding: .month, value: (i - 11), to: now) ?? now
                let m = cal.component(.month, from: targetDate)
                let y = cal.component(.year, from: targetDate)
                let pages = history.filter {
                    cal.component(.month, from: $0.date) == m && cal.component(.year, from: $0.date) == y
                }.reduce(0) { $0 + $1.pagesRead }
                return ReadingDataPoint(label: monthNames[m - 1], pages: pages, index: i)
            }
        }
    }
    
    private var totalPagesInPeriod: Int {
        dataPoints.reduce(0) { $0 + $1.pages }
    }
    
    private var targetForPeriod: Int {
        switch selectedPeriod {
        case .days7: return 175
        case .days30: return 750
        case .months6: return 4500
        case .months12: return 9000
        }
    }
    
    private var averageTargetPerPoint: Double {
        guard !dataPoints.isEmpty else { return 25.0 }
        return Double(targetForPeriod) / Double(dataPoints.count)
    }
    
    private var isAboveTarget: Bool {
        totalPagesInPeriod >= targetForPeriod
    }
    
    private var diffPercent: Int {
        guard targetForPeriod > 0 else { return 0 }
        return Int((Double(totalPagesInPeriod - targetForPeriod) / Double(targetForPeriod)) * 100)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок и селектор периода
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ТЕМПОРИТМ ЧТЕНИЯ")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .tracking(0.5)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(totalPagesInPeriod)")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(UIColor.label))
                        
                        Text("стр.")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        // Бейдж сравнения с таргетом
                        Text(isAboveTarget ? "+\(diffPercent)% к цели" : "\(diffPercent)% от цели")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(isAboveTarget ? .green : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((isAboveTarget ? Color.green : Color.orange).opacity(0.12))
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                // Переключатель периода
                HStack(spacing: 2) {
                    ForEach(VelocityPeriod.allCases) { period in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPeriod = period
                            }
                        }) {
                            Text(period.rawValue)
                                .font(.caption2)
                                .fontWeight(selectedPeriod == period ? .bold : .medium)
                                .foregroundColor(selectedPeriod == period ? Color(UIColor.label) : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(selectedPeriod == period ? Color(UIColor.systemBackground) : Color.clear)
                                .cornerRadius(8)
                                .shadow(color: selectedPeriod == period ? Color.black.opacity(0.06) : Color.clear, radius: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(10)
            }
            
            // Легенда
            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 0.85, green: 0.33, blue: 0.18))
                        .frame(width: 8, height: 8)
                    Text("Прочитано")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 5) {
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: 16, height: 1.5)
                        .foregroundColor(.secondary)
                    Text("Целевая норма: \(targetForPeriod) стр.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // График SwiftCharts
            Chart {
                // Пунктирная целевая линия (Target Line)
                RuleMark(
                    y: .value("Target", averageTargetPerPoint)
                )
                .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                .foregroundStyle(Color.secondary.opacity(0.6))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Норма")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                // Сглаженная площадь заливки
                ForEach(dataPoints) { pt in
                    AreaMark(
                        x: .value("Time", pt.label),
                        y: .value("Pages", pt.pages)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.33, blue: 0.18).opacity(0.35),
                                Color(red: 0.85, green: 0.33, blue: 0.18).opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Time", pt.label),
                        y: .value("Pages", pt.pages)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .foregroundStyle(Color(red: 0.85, green: 0.33, blue: 0.18))
                    .symbol {
                        Circle()
                            .fill(Color(red: 0.85, green: 0.33, blue: 0.18))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(height: 135)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel()
                        .font(.system(size: 9))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 9))
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

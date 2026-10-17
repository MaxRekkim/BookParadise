import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct CognitiveFlowStateView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State public var metrics: CognitiveFlowMetrics = CognitiveFlowEngine.evaluateFlow(
        sessionDurationMinutes: 45,
        averageSpeedPPH: 34.0,
        pauseCount: 1
    )
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Flow State Speedometer Gauge
            gaugeCard
            
            // Sub-metrics Grid (Stability, Eye Strain, Streak)
            metricsGrid
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
                    Text("КОГНИТИВНЫЙ РЕЗОНАНС")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("FLOW STATE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(metrics.currentZone.badgeColor))
                }
                
                Text(metrics.currentZone.rawValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: metrics.currentZone.iconName)
                .font(.title2)
                .foregroundColor(metrics.currentZone.badgeColor)
        }
    }
    
    // MARK: - Gauge Card
    private var gaugeCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Индекс фокуса и погружения")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Spacer()
                Text("\(Int(metrics.flowScore)) / 100")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(metrics.currentZone.badgeColor)
            }
            
            // Progress Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(height: 10)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [metrics.currentZone.badgeColor.opacity(0.7), metrics.currentZone.badgeColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(metrics.flowScore / 100.0)), height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
        )
    }
    
    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        HStack(spacing: 10) {
            metricCard(title: "Непрерывность", value: "\(metrics.focusMinutesStreak) мин", icon: "timer")
            metricCard(title: "Стабильность", value: "\(Int(metrics.paceStabilityPercent))%", icon: "speedometer")
            metricCard(title: "Зрение", value: metrics.eyeStrainAlertNeeded ? "Нужен отдых" : "В норме", icon: "eye.fill", highlight: metrics.eyeStrainAlertNeeded)
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, highlight: Bool = false) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(highlight ? .orange : theme.primaryAccent)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color(UIColor.label))
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5))
        )
    }
}

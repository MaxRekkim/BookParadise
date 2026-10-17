import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ReadingChronotypeView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State public var profile: ReadingCircadianProfile = ReadingChronotypeEngine.analyzeSessionHours([22, 23, 23, 0, 1, 8, 9, 14, 19, 20, 23, 23])
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Dominant Chronotype Badge
            dominantChronotypeBanner
            
            // 4-Quadrant Circadian Breakdown Bars
            circadianQuadrantBars
            
            // Advice Callout
            adviceSection
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
                    Text("БИОРИТМЫ ЧТЕНИЯ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("ЦИРКАДНЫЙ ХРОНОТИП")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(profile.dominantChronotype.accentColor))
                }
                
                Text(profile.dominantChronotype.rawValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: profile.dominantChronotype.iconName)
                .font(.title2)
                .foregroundColor(profile.dominantChronotype.accentColor)
        }
    }
    
    // MARK: - Dominant Banner
    private var dominantChronotypeBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(profile.dominantChronotype.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: profile.dominantChronotype.iconName)
                    .font(.title3)
                    .foregroundColor(profile.dominantChronotype.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Пик когнитивного восприятия")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text("Около \(profile.peakHourString)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
        )
    }
    
    // MARK: - Quadrant Bars
    private var circadianQuadrantBars: some View {
        VStack(spacing: 6) {
            quadrantRow(title: "Утро (05:00–11:00)", ratio: profile.morningRatio, color: .orange)
            quadrantRow(title: "День (11:00–17:00)", ratio: profile.afternoonRatio, color: .yellow)
            quadrantRow(title: "Вечер (17:00–22:00)", ratio: profile.eveningRatio, color: .purple)
            quadrantRow(title: "Ночь (22:00–05:00)", ratio: profile.nightRatio, color: .indigo)
        }
    }
    
    private func quadrantRow(title: String, ratio: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .frame(width: 120, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.12))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(ratio))
                }
            }
            .frame(height: 5)
            
            Text("\(Int(ratio * 100))%")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color(UIColor.label))
                .frame(width: 32, alignment: .trailing)
        }
    }
    
    // MARK: - Advice Section
    private var adviceSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(theme.primaryAccent)
            
            Text(profile.dominantChronotype.optimalWindowAdvice)
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
}

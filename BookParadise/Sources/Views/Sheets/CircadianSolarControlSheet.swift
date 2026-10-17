import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct CircadianSolarControlSheet: View {
    @ObservedObject private var solar = CircadianSolarEngine.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Status Card
                    currentPhaseHeroCard
                    
                    // Auto Astronomical Toggle
                    autoAstronomicalToggleCard
                    
                    // Manual Phase Selector Grid
                    phasesSelectorSection
                    
                    // Photobiological Spectrum & Eye Strain Diagnostics
                    photobiologyMetricsCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Циркадный свет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(theme.primaryAccent)
                }
            }
        }
    }
    
    // MARK: - Current Phase Hero Card
    private var currentPhaseHeroCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(solar.currentPhase.accentTint.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: solar.currentPhase.icon)
                        .font(.title)
                        .foregroundColor(solar.currentPhase.accentTint)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(solar.currentPhase.rawValue)
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("Высота солнца: \(String(format: "%.1f°", solar.solarElevationDegrees))")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(solar.currentPhase.kelvin)K")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(solar.currentPhase.accentTint)
                    Text("Спектр")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            Text(solar.currentPhase.description)
                .font(.footnote)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(solar.currentPhase.accentTint.opacity(0.35), lineWidth: 1.5)
                )
                .shadow(color: solar.currentPhase.accentTint.opacity(0.12), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Auto Astronomical Toggle Card
    private var autoAstronomicalToggleCard: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $solar.isAutoAstronomicalEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Астрономический автопилот")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    Text("Автоматическая подстройка цветовой температуры под естественное положение солнца")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
            .tint(theme.primaryAccent)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Phases Selector Section
    private var phasesSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ФАЗЫ ОСВЕЩЕНИЯ")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .tracking(1.2)
            
            VStack(spacing: 10) {
                ForEach(CircadianSolarPhase.allCases) { phase in
                    Button(action: {
                        solar.setManualPhase(phase)
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: phase.icon)
                                .font(.body.weight(.semibold))
                                .foregroundColor(phase.accentTint)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phase.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(UIColor.label))
                                
                                Text(phase.description)
                                    .font(.caption2)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if solar.currentPhase == phase {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.primaryAccent)
                                    .font(.headline)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(solar.currentPhase == phase ? theme.primaryAccent.opacity(0.12) : Color(UIColor.secondarySystemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(solar.currentPhase == phase ? theme.primaryAccent.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Photobiology Metrics Card
    private var photobiologyMetricsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ФОТОБИОЛОГИЧЕСКАЯ ЗАЩИТА")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .tracking(1.2)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Подавление синего спектра")
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.label))
                    Spacer()
                    Text("\(Int(solar.currentPhase.melatoninProtectionScore * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(solar.currentPhase.accentTint)
                }
                
                ProgressView(value: solar.currentPhase.melatoninProtectionScore)
                    .tint(solar.currentPhase.accentTint)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Мелатонин")
                            .font(.caption2)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text(solar.currentPhase.melatoninProtectionScore > 0.8 ? "В безопасности" : "Подавляется")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(solar.currentPhase.melatoninProtectionScore > 0.8 ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Родопсин (палочки)")
                            .font(.caption2)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Text(solar.currentPhase == .rubyDark ? "100% активен" : "Дневной режим")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(solar.currentPhase == .rubyDark ? .red : .blue)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
}

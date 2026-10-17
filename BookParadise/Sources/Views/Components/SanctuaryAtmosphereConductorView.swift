import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct SanctuaryAtmosphereConductorView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State public var state: SanctuaryAtmosphereState = .defaultState
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Active Soundscape Hero Card
            heroPresetCard
            
            // Preset Selection Grid
            presetGrid
            
            // Spatial 3D Width & Master Volume Sliders
            audioControlsSection
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
                    Text("АКУСТИЧЕСКИЙ ДИРИЖЁР")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("SPATIAL 3D SOUND")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.teal))
                }
                
                Text("Иммерсивный звуковой купол")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Button(action: {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    state.togglePlayback()
                }
            }) {
                Image(systemName: state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(theme.primaryAccent)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Hero Preset Card
    private var heroPresetCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.primaryAccent.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: state.activePreset.iconName)
                    .font(.title3)
                    .foregroundColor(theme.primaryAccent)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(state.activePreset.rawValue)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                
                Text(state.activePreset.subtitle)
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
        )
    }
    
    // MARK: - Preset Selection Grid
    private var presetGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SanctuarySoundscapePreset.allCases) { preset in
                    let isSelected = state.activePreset == preset
                    Button(action: {
                        #if canImport(UIKit)
                        UISelectionFeedbackGenerator().selectionChanged()
                        #endif
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            state.activePreset = preset
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: preset.iconName)
                                .font(.system(size: 11))
                            Text(preset.rawValue)
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(isSelected ? theme.primaryAccent : Color(UIColor.tertiarySystemGroupedBackground))
                        )
                        .foregroundColor(isSelected ? .white : Color(UIColor.label))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Audio Controls
    private var audioControlsSection: some View {
        VStack(spacing: 10) {
            // Master Volume
            HStack(spacing: 10) {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Slider(value: $state.masterVolume, in: 0.0...1.0)
                    .accentColor(theme.primaryAccent)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Text("\(Int(state.masterVolume * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.primaryAccent)
                    .frame(width: 32, alignment: .trailing)
            }
            
            // Spatial 3D Binaural Width
            HStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.caption2)
                    .foregroundColor(.teal)
                
                Text("Пространственная сцена (Binaural 3D)")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                Spacer()
                
                Text("\(Int(state.spatialBinauralWidth * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.teal)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.4))
        )
    }
}

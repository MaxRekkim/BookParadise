import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct MenuBarCompanionView: View {
    @State public var state: MenuBarCompanionState
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isPopoverOpen: Bool = true
    
    public init(state: MenuBarCompanionState = .sampleActiveState) {
        _state = State(initialValue: state)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // macOS Menu Bar Simulation Strip
            macMenuBarStrip
            
            // Popover Dropdown Card
            if isPopoverOpen {
                menuBarPopoverCard
                    .transition(.move(edge: .top).combined(with: .opacity))
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
                    Text("MACOS MENU BAR COMPANION")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("STATUS ITEM")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.teal))
                }
                
                Text("Фоновое управление на рабочем столе Mac")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "menubar.rectangle")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Menu Bar Strip
    private var macMenuBarStrip: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .font(.system(size: 11))
                Text("BookParadise")
                    .font(.system(size: 11, weight: .bold))
                Text("Файл")
                    .font(.system(size: 11))
                Text("Правка")
                    .font(.system(size: 11))
            }
            .foregroundColor(Color(UIColor.secondaryLabel))
            
            Spacer()
            
            // Status Item
            Button(action: {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isPopoverOpen.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(state.statusItemTitleString)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Image(systemName: isPopoverOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isPopoverOpen ? theme.primaryAccent : Color.secondary.opacity(0.15))
                )
                .foregroundColor(isPopoverOpen ? .white : Color(UIColor.label))
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 6) {
                Image(systemName: "wifi")
                    .font(.system(size: 10))
                Image(systemName: "battery.100")
                    .font(.system(size: 11))
                Text("22:15")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(Color(UIColor.secondaryLabel))
            .padding(.leading, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
    
    // MARK: - Popover Dropdown Card
    private var menuBarPopoverCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book Info Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.currentBookTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    
                    Text("\(state.author) • \(state.currentPage) из \(state.totalPages) стр.")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(state.currentPacePPH)) с/ч")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(theme.primaryAccent)
                    Text("текущий темп")
                        .font(.system(size: 8))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
            }
            
            // Daily Quota Progress Gauge
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Дневная цель")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text("\(state.pagesLoggedToday)/\(state.dailyTarget) стр.")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(UIColor.label))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(theme.primaryAccent)
                            .frame(width: geo.size.width * CGFloat(state.quotaProgressRatio))
                    }
                }
                .frame(height: 5)
            }
            
            Divider()
            
            // Soundscape Quick Toggle
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: state.isSoundscapePlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.caption)
                        .foregroundColor(state.isSoundscapePlaying ? .green : Color(UIColor.secondaryLabel))
                    
                    Text(state.activeSoundscapeName)
                        .font(.caption)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                Button(action: {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    state.toggleSoundscape()
                }) {
                    Text(state.isSoundscapePlaying ? "Выкл" : "Вкл")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(state.isSoundscapePlaying ? .orange : .green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
            
            // Quick Log Buttons
            HStack(spacing: 8) {
                quickLogPill(delta: 5)
                quickLogPill(delta: 10)
                quickLogPill(delta: 25)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private func quickLogPill(delta: Int) -> some View {
        Button(action: {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                state.logPages(delta: delta)
            }
        }) {
            HStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                Text("\(delta) стр")
                    .font(.system(size: 10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(theme.primaryAccent.opacity(0.14))
            )
            .foregroundColor(theme.primaryAccent)
        }
        .buttonStyle(.plain)
    }
}

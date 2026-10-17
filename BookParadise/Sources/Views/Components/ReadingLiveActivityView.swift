import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ReadingLiveActivityView: View {
    @State public var session: ReadingLiveActivitySession
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    public enum DynamicIslandMode: String, CaseIterable, Identifiable {
        case compact = "Компактный (Dynamic Island)"
        case expanded = "Развернутый (Lock Screen)"
        
        public var id: String { rawValue }
    }
    
    @State private var selectedMode: DynamicIslandMode = .expanded
    
    public init(session: ReadingLiveActivitySession = .sampleActiveSession) {
        _session = State(initialValue: session)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Mode Picker
            Picker("Режим Live Activity", selection: $selectedMode.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
                ForEach(DynamicIslandMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Dynamic Island Visual Renderers
            if selectedMode == .compact {
                compactDynamicIslandPreview
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                expandedLiveActivityCard
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
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("LIVE ACTIVITIES")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("DYNAMIC ISLAND")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.purple))
                }
                
                Text("Фокус-сессия на экране блокировки")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "timer.circle.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Compact Dynamic Island View
    private var compactDynamicIslandPreview: some View {
        HStack {
            Spacer()
            HStack(spacing: 12) {
                // Leading Island Element
                HStack(spacing: 5) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.primaryAccent)
                    
                    Circle()
                        .fill(session.state.isPaused ? Color.orange : Color.green)
                        .frame(width: 5, height: 5)
                }
                
                Spacer()
                
                // Trailing Island Element
                HStack(spacing: 6) {
                    Text("\(session.state.currentSpeedWPM) WPM")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    Text(session.state.formattedElapsedTime)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(width: 250, height: 38)
            .background(Capsule().fill(Color.black))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Expanded Live Activity Card (Banner on Lock Screen)
    private var expandedLiveActivityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Row: Book info & Soundscape pill
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.bookTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(session.author)
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.65))
                }
                
                Spacer()
                
                if let sound = session.state.soundscapeName {
                    HStack(spacing: 4) {
                        Image(systemName: "headphones")
                            .font(.system(size: 9))
                        Text(sound)
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                }
            }
            
            // Middle Row: Big Timer & Speedometer
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.state.formattedElapsedTime)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Цель: \(session.state.targetDurationMinutes) мин (осталось ~\(session.state.remainingMinutes) мин)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(session.state.currentSpeedWPM)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.green)
                    Text("слов/мин (WPM)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.primaryAccent, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(session.state.progressRatio))
                }
            }
            .frame(height: 6)
            
            // Bottom Row: Action Controls (+1 Page, Pause, Session info)
            HStack(spacing: 10) {
                Button(action: {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    session.logPage()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .heavy))
                        Text("Страница (\(session.state.pagesReadInSession))")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                    session.togglePause()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: session.state.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 10))
                        Text(session.state.isPaused ? "Продолжить" : "Пауза")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(session.state.isPaused ? Color.green : Color.orange))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text("\(session.currentBookPage)/\(session.totalBookPages) стр.")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
        )
    }
}

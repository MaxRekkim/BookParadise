import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct AppIntentsConfigView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var shortcuts: [BookAppShortcutTemplate] = AppIntentsExecutionEngine.curatedShortcuts
    @State private var activeSpeechBubble: String? = nil
    @State private var addedShortcutIds: Set<UUID> = []
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Speech Simulation Bubble
            if let speech = activeSpeechBubble {
                siriSpeechBubble(text: speech)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Shortcuts List
            VStack(spacing: 10) {
                ForEach(shortcuts) { item in
                    shortcutRow(item: item)
                }
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
                    Text("SIRI SHORTCUTS & APP INTENTS")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("ГОЛОСОВОЙ КОНТРОЛЬ")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.purple))
                }
                
                Text("Голосовые команды и автоматизация")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Siri Speech Bubble
    private func siriSpeechBubble(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "waveform")
                .font(.title3)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ОТВЕТ SIRI")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.purple)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Button(action: {
                withAnimation { activeSpeechBubble = nil }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.purple.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Shortcut Row
    private func shortcutRow(item: BookAppShortcutTemplate) -> some View {
        let isAdded = addedShortcutIds.contains(item.id)
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: item.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.primaryAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    
                    Text(item.triggerPhrase)
                        .font(.caption2)
                        .italic()
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                // Test Siri Trigger Button
                Button(action: {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        activeSpeechBubble = item.verbalResponsePreview
                    }
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.primaryAccent)
                }
                .buttonStyle(.plain)
                
                // Add to Shortcuts button
                Button(action: {
                    #if canImport(UIKit)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                    withAnimation {
                        if isAdded {
                            addedShortcutIds.remove(item.id)
                        } else {
                            addedShortcutIds.insert(item.id)
                        }
                    }
                }) {
                    Text(isAdded ? "Добавлено" : "+ В Siri")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isAdded ? .white : theme.primaryAccent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isAdded ? Color.green : theme.primaryAccent.opacity(0.14))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.7))
        )
    }
}

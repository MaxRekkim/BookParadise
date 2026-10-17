import SwiftUI

public struct SpoilerShieldView<Content: View>: View {
    public let isSpoiler: Bool
    public let spoilerTag: String?
    public let content: () -> Content
    
    @State private var isRevealed: Bool = false
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(
        isSpoiler: Bool = true,
        spoilerTag: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isSpoiler = isSpoiler
        self.spoilerTag = spoilerTag
        self.content = content
    }
    
    public var body: some View {
        if !isSpoiler {
            content()
        } else {
            ZStack {
                content()
                    .blur(radius: isRevealed ? 0 : 12)
                    .allowsHitTesting(isRevealed)
                
                if !isRevealed {
                    // Размытый защитный экран (Frosted Glass Shield)
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            isRevealed = true
                        }
                        HapticManager.shared.mediumTap()
                    }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.caption)
                                Text(spoilerTag ?? "Спойлер")
                                    .font(.caption)
                                    .fontWeight(.heavy)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.purple))
                            
                            Text("Нажмите, чтобы прочитать")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .overlay(alignment: .topTrailing) {
                if isRevealed {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isRevealed = false
                        }
                        HapticManager.shared.lightTap()
                    }) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Circle().fill(Color(UIColor.tertiarySystemFill)))
                    }
                    .padding(6)
                }
            }
        }
    }
}

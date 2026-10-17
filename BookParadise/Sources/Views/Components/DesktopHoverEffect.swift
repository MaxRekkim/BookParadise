import SwiftUI

public struct DesktopHoverEffectModifier: ViewModifier {
    @State private var isHovered: Bool = false
    public var scale: CGFloat
    public var yOffset: CGFloat

    public init(scale: CGFloat = 1.03, yOffset: CGFloat = -2) {
        self.scale = scale
        self.yOffset = yOffset
    }

    public func body(content: Content) -> some View {
        #if targetEnvironment(macCatalyst) || os(macOS)
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .offset(y: isHovered ? yOffset : 0)
            .shadow(color: Color.black.opacity(isHovered ? 0.18 : 0.05), radius: isHovered ? 8 : 2, x: 0, y: isHovered ? 4 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        #else
        content
        #endif
    }
}

extension View {
    public func desktopHover(scale: CGFloat = 1.03, yOffset: CGFloat = -2) -> some View {
        self.modifier(DesktopHoverEffectModifier(scale: scale, yOffset: yOffset))
    }
}

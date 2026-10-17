import SwiftUI

public struct FloatingQuickDockView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    public var onSearchTapped: () -> Void
    public var onAddBookTapped: () -> Void
    public var onTimerTapped: () -> Void
    public var onQuotesTapped: () -> Void
    public var onOracleTapped: () -> Void
    
    public init(
        viewModel: LibraryViewModel,
        onSearchTapped: @escaping () -> Void,
        onAddBookTapped: @escaping () -> Void,
        onTimerTapped: @escaping () -> Void,
        onQuotesTapped: @escaping () -> Void,
        onOracleTapped: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onSearchTapped = onSearchTapped
        self.onAddBookTapped = onAddBookTapped
        self.onTimerTapped = onTimerTapped
        self.onQuotesTapped = onQuotesTapped
        self.onOracleTapped = onOracleTapped
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // 1. Поиск
            dockButton(icon: "magnifyingglass", action: onSearchTapped)
            
            dockDivider
            
            // 2. Добавить книгу
            dockButton(icon: "plus", action: onAddBookTapped)
            
            dockDivider
            
            // 3. Сессия чтения
            dockButton(icon: "timer", action: onTimerTapped)
            
            dockDivider
            
            // 4. Цитаты
            dockButton(icon: "quote.bubble", action: onQuotesTapped)
            
            dockDivider
            
            // 5. Оракул-Сомелье
            dockButton(icon: "sparkles", accentColor: Color(red: 0.90, green: 0.72, blue: 0.23), action: onOracleTapped)
            
            dockDivider
            
            // 6. Переключение темы
            dockButton(icon: "circle.lefthalf.filled") {
                withAnimation {
                    theme.selectedTheme = (theme.selectedTheme == .midnightOxford ? .wineVelvet : .midnightOxford)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.92))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 6)
    }
    
    private func dockButton(icon: String, accentColor: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(accentColor ?? .white.opacity(0.85))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var dockDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 16)
    }
}

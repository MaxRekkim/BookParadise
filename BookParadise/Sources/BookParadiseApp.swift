import SwiftUI

@main
public struct BookParadiseApp: App {
    @ObservedObject private var theme = ThemeManager.shared

    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(theme.primaryAccent)
        }
    }
}

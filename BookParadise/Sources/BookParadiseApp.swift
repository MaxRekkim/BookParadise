import SwiftUI

@main
public struct BookParadiseApp: App {
    @ObservedObject private var theme = ThemeManager.shared

    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(theme.primaryAccent)
                #if targetEnvironment(macCatalyst) || os(macOS)
                .frame(minWidth: 980, idealWidth: 1200, minHeight: 680, idealHeight: 820)
                #endif
        }
        #if targetEnvironment(macCatalyst) || os(macOS)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}

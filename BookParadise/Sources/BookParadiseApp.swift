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
                .frame(minWidth: 850, idealWidth: 1050, minHeight: 620, idealHeight: 750)
                #endif
        }
        #if targetEnvironment(macCatalyst) || os(macOS)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}

import SwiftUI

@main
public struct BookParadiseApp: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            MainTabView()
                .accentColor(.orange)
        }
    }
}

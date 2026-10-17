import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public final class HapticManager {
    public static let shared = HapticManager()
    private init() {}

    public func lightTap() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    public func mediumTap() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    public func heavyTap() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    public func success() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }

    public func notificationSuccess() {
        success()
    }

    public func selectionChanged() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }

    public func levelUp() {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
        #endif
    }
}

import Foundation
import SwiftUI

public struct RPGRankInfo {
    public let level: Int
    public let title: String
    public let icon: String
    public let color: Color
    public let perkDescription: String
}

public struct RPGState: Codable {
    public var totalXP: Int
    public var unlockedPerks: [String]

    public init(totalXP: Int = 0, unlockedPerks: [String] = []) {
        self.totalXP = totalXP
        self.unlockedPerks = unlockedPerks
    }
}

import Foundation
import SwiftUI

// MARK: - Модель состояния менюбара macOS (MenuBar Companion)
public struct MenuBarCompanionState: Identifiable, Codable, Equatable {
    public let id: UUID
    public var currentBookTitle: String
    public var author: String
    public var currentPage: Int
    public var totalPages: Int
    public var pagesLoggedToday: Int
    public var dailyTarget: Int
    public var currentPacePPH: Double // Страниц в час
    public var isSoundscapePlaying: Bool
    public var activeSoundscapeName: String
    
    public init(
        id: UUID = UUID(),
        bookTitle: String = "Мастер и Маргарита",
        author: String = "Михаил Булгаков",
        currentPage: Int = 215,
        totalPages: Int = 384,
        pagesLoggedToday: Int = 18,
        dailyTarget: Int = 30,
        currentPacePPH: Double = 34.0,
        isSoundscapePlaying: Bool = true,
        activeSoundscapeName: String = "Дождь и библиотека"
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.author = author
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.pagesLoggedToday = pagesLoggedToday
        self.dailyTarget = dailyTarget
        self.currentPacePPH = currentPacePPH
        self.isSoundscapePlaying = isSoundscapePlaying
        self.activeSoundscapeName = activeSoundscapeName
    }
    
    public var statusItemTitleString: String {
        "📖 \(Int(currentPacePPH)) с/ч"
    }
    
    public var quotaProgressRatio: Double {
        min(Double(pagesLoggedToday) / Double(max(dailyTarget, 1)), 1.0)
    }
    
    public mutating func logPages(delta: Int) {
        self.currentPage = min(currentPage + delta, totalPages)
        self.pagesLoggedToday += delta
    }
    
    public mutating func toggleSoundscape() {
        self.isSoundscapePlaying.toggle()
    }
    
    public static var sampleActiveState: MenuBarCompanionState {
        MenuBarCompanionState()
    }
}

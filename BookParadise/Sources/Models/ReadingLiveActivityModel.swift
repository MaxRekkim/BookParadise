import Foundation
import SwiftUI

// MARK: - Состояние сессии Live Activity для Dynamic Island
public struct ReadingLiveActivityContentState: Codable, Hashable, Equatable {
    public var elapsedSeconds: Int
    public var targetDurationMinutes: Int
    public var pagesReadInSession: Int
    public var currentSpeedWPM: Int
    public var isPaused: Bool
    public var soundscapeName: String?
    
    public init(
        elapsedSeconds: Int = 0,
        targetDurationMinutes: Int = 30,
        pagesReadInSession: Int = 0,
        currentSpeedWPM: Int = 240,
        isPaused: Bool = false,
        soundscapeName: String? = "Шум дождя"
    ) {
        self.elapsedSeconds = elapsedSeconds
        self.targetDurationMinutes = targetDurationMinutes
        self.pagesReadInSession = pagesReadInSession
        self.currentSpeedWPM = currentSpeedWPM
        self.isPaused = isPaused
        self.soundscapeName = soundscapeName
    }
    
    public var progressRatio: Double {
        let targetSec = max(targetDurationMinutes * 60, 1)
        return min(Double(elapsedSeconds) / Double(targetSec), 1.0)
    }
    
    public var formattedElapsedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    public var remainingMinutes: Int {
        let totalSec = targetDurationMinutes * 60
        let leftSec = max(totalSec - elapsedSeconds, 0)
        return leftSec / 60
    }
}

// MARK: - Атрибуты активности (ActivityKit)
public struct ReadingLiveActivitySession: Identifiable, Codable, Equatable {
    public let id: UUID
    public var bookTitle: String
    public var author: String
    public var currentBookPage: Int
    public var totalBookPages: Int
    public var state: ReadingLiveActivityContentState
    
    public init(
        id: UUID = UUID(),
        bookTitle: String,
        author: String,
        currentBookPage: Int,
        totalBookPages: Int,
        state: ReadingLiveActivityContentState = ReadingLiveActivityContentState()
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.author = author
        self.currentBookPage = currentBookPage
        self.totalBookPages = totalBookPages
        self.state = state
    }
    
    public mutating func tickSecond() {
        guard !state.isPaused else { return }
        state.elapsedSeconds += 1
    }
    
    public mutating func togglePause() {
        state.isPaused.toggle()
    }
    
    public mutating func logPage() {
        state.pagesReadInSession += 1
        currentBookPage = min(currentBookPage + 1, totalBookPages)
    }
    
    public static var sampleActiveSession: ReadingLiveActivitySession {
        ReadingLiveActivitySession(
            bookTitle: "Мастер и Маргарита",
            author: "Михаил Булгаков",
            currentBookPage: 215,
            totalBookPages: 384,
            state: ReadingLiveActivityContentState(
                elapsedSeconds: 845,
                targetDurationMinutes: 30,
                pagesReadInSession: 14,
                currentSpeedWPM: 265,
                isPaused: false,
                soundscapeName: "Камин и кофе"
            )
        )
    }
}

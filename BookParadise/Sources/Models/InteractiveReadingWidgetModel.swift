import Foundation
import SwiftUI

// MARK: - Модель интерактивного виджета для экрана блокировки и Home Screen
public struct InteractiveWidgetState: Identifiable, Codable, Equatable {
    public let id: UUID
    public var bookTitle: String
    public var author: String
    public var currentPage: Int
    public var totalPages: Int
    public var streakDays: Int
    public var dailyQuotaTarget: Int
    public var dailyPagesReadToday: Int
    public var lastLoggedAt: Date
    
    public init(
        id: UUID = UUID(),
        bookTitle: String,
        author: String,
        currentPage: Int,
        totalPages: Int,
        streakDays: Int,
        dailyQuotaTarget: Int = 30,
        dailyPagesReadToday: Int = 0,
        lastLoggedAt: Date = Date()
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.author = author
        self.currentPage = min(currentPage, totalPages)
        self.totalPages = max(totalPages, 1)
        self.streakDays = streakDays
        self.dailyQuotaTarget = max(dailyQuotaTarget, 1)
        self.dailyPagesReadToday = dailyPagesReadToday
        self.lastLoggedAt = lastLoggedAt
    }
    
    public var progressPercent: Double {
        (Double(currentPage) / Double(totalPages)) * 100.0
    }
    
    public var dailyQuotaPercent: Double {
        min((Double(dailyPagesReadToday) / Double(dailyQuotaTarget)) * 100.0, 100.0)
    }
    
    public var remainingBookPages: Int {
        max(totalPages - currentPage, 0)
    }
    
    // Мутация состояния при быстром логировании (+N страниц)
    public mutating func incrementPages(by delta: Int) {
        let actualDelta = min(delta, remainingBookPages)
        guard actualDelta > 0 else { return }
        self.currentPage += actualDelta
        self.dailyPagesReadToday += actualDelta
        self.lastLoggedAt = Date()
    }
    
    public static var sampleActiveState: InteractiveWidgetState {
        InteractiveWidgetState(
            bookTitle: "Мастер и Маргарита",
            author: "Михаил Булгаков",
            currentPage: 215,
            totalPages: 384,
            streakDays: 14,
            dailyQuotaTarget: 30,
            dailyPagesReadToday: 18
        )
    }
}

// MARK: - Типы аксессуаров для экрана блокировки (Lock Screen Accessories)
public enum LockScreenAccessoryStyle: String, CaseIterable, Identifiable {
    case circular = "Круглый (AccessoryCircular)"
    case rectangular = "Прямоугольный (AccessoryRectangular)"
    case inline = "В строке даты (AccessoryInline)"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .circular: return "circle.dashed"
        case .rectangular: return "rectangle.dashed"
        case .inline: return "text.alignleft"
        }
    }
}

// MARK: - Мост синхронизации через App Groups (AppGroupSyncBridge)
public struct AppGroupSyncBridge {
    public static let appGroupIdentifier = "group.com.maxim.bookparadise"
    public static let sharedStateKey = "BookParadise_InteractiveWidgetState"
    
    public static func saveToAppGroup(_ state: InteractiveWidgetState) {
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let data = try? JSONEncoder().encode(state) {
            sharedDefaults.set(data, forKey: sharedStateKey)
        }
    }
    
    public static func loadFromAppGroup() -> InteractiveWidgetState? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: sharedStateKey),
              let state = try? JSONDecoder().decode(InteractiveWidgetState.self, from: data) else {
            return nil
        }
        return state
    }
}

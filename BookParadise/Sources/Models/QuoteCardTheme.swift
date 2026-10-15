import SwiftUI

/// Темы и стили оформления для открыток с цитатами
public enum QuoteCardTheme: String, CaseIterable, Identifiable, Codable {
    case parchment = "parchment"     // Винтажный пергамент (классика)
    case midnight = "midnight"       // Глубокая полуночная синева
    case lavender = "lavender"       // Пастельная лаванда и сумерки
    case emerald = "emerald"         // Изумрудная хвоя и свежий шалфей
    case vintageCoffee = "coffee"    // Кофейный винтаж и карамель
    case monochrome = "monochrome"   // Минималистичный чистый монохром

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .parchment: return "Пергамент"
        case .midnight: return "Полночь"
        case .lavender: return "Лаванда"
        case .emerald: return "Изумруд"
        case .vintageCoffee: return "Кофе"
        case .monochrome: return "Монохром"
        }
    }

    public var icon: String {
        switch self {
        case .parchment: return "scroll.fill"
        case .midnight: return "moon.stars.fill"
        case .lavender: return "sparkles"
        case .emerald: return "leaf.fill"
        case .vintageCoffee: return "cup.and.saucer.fill"
        case .monochrome: return "circle.lefthalf.filled"
        }
    }

    public var cardBackground: Color {
        switch self {
        case .parchment: return Color(red: 0.97, green: 0.95, blue: 0.91)
        case .midnight: return Color(red: 0.09, green: 0.11, blue: 0.15)
        case .lavender: return Color(red: 0.96, green: 0.93, blue: 0.98)
        case .emerald: return Color(red: 0.91, green: 0.96, blue: 0.93)
        case .vintageCoffee: return Color(red: 0.94, green: 0.90, blue: 0.85)
        case .monochrome: return Color(red: 0.99, green: 0.99, blue: 0.99)
        }
    }

    public var primaryText: Color {
        switch self {
        case .parchment: return Color(red: 0.14, green: 0.12, blue: 0.10)
        case .midnight: return Color(red: 0.94, green: 0.96, blue: 0.98)
        case .lavender: return Color(red: 0.18, green: 0.12, blue: 0.24)
        case .emerald: return Color(red: 0.08, green: 0.16, blue: 0.11)
        case .vintageCoffee: return Color(red: 0.18, green: 0.13, blue: 0.09)
        case .monochrome: return Color(red: 0.07, green: 0.09, blue: 0.13)
        }
    }

    public var secondaryText: Color {
        switch self {
        case .parchment: return Color(red: 0.44, green: 0.38, blue: 0.34)
        case .midnight: return Color(red: 0.65, green: 0.72, blue: 0.82)
        case .lavender: return Color(red: 0.46, green: 0.36, blue: 0.54)
        case .emerald: return Color(red: 0.22, green: 0.38, blue: 0.28)
        case .vintageCoffee: return Color(red: 0.45, green: 0.34, blue: 0.26)
        case .monochrome: return Color(red: 0.40, green: 0.44, blue: 0.52)
        }
    }

    public var accentColor: Color {
        switch self {
        case .parchment: return Color(red: 0.78, green: 0.45, blue: 0.16)
        case .midnight: return Color(red: 0.38, green: 0.65, blue: 0.98)
        case .lavender: return Color(red: 0.58, green: 0.32, blue: 0.88)
        case .emerald: return Color(red: 0.10, green: 0.65, blue: 0.45)
        case .vintageCoffee: return Color(red: 0.70, green: 0.36, blue: 0.12)
        case .monochrome: return Color(red: 0.20, green: 0.23, blue: 0.28)
        }
    }

    public var noteBackground: Color {
        switch self {
        case .parchment: return Color(red: 0.92, green: 0.89, blue: 0.84)
        case .midnight: return Color(red: 0.15, green: 0.18, blue: 0.25)
        case .lavender: return Color(red: 0.91, green: 0.86, blue: 0.95)
        case .emerald: return Color(red: 0.83, green: 0.91, blue: 0.86)
        case .vintageCoffee: return Color(red: 0.89, green: 0.83, blue: 0.76)
        case .monochrome: return Color(red: 0.94, green: 0.95, blue: 0.96)
        }
    }

    public var dividerColor: Color {
        switch self {
        case .parchment: return Color(red: 0.84, green: 0.80, blue: 0.74)
        case .midnight: return Color(red: 0.22, green: 0.27, blue: 0.36)
        case .lavender: return Color(red: 0.86, green: 0.80, blue: 0.91)
        case .emerald: return Color(red: 0.77, green: 0.86, blue: 0.80)
        case .vintageCoffee: return Color(red: 0.83, green: 0.76, blue: 0.68)
        case .monochrome: return Color(red: 0.88, green: 0.90, blue: 0.92)
        }
    }

    public var borderColor: Color {
        switch self {
        case .parchment: return Color(red: 0.78, green: 0.45, blue: 0.16).opacity(0.2)
        case .midnight: return Color(red: 0.38, green: 0.65, blue: 0.98).opacity(0.3)
        case .lavender: return Color(red: 0.58, green: 0.32, blue: 0.88).opacity(0.25)
        case .emerald: return Color(red: 0.10, green: 0.65, blue: 0.45).opacity(0.25)
        case .vintageCoffee: return Color(red: 0.70, green: 0.36, blue: 0.12).opacity(0.25)
        case .monochrome: return Color(red: 0.20, green: 0.23, blue: 0.28).opacity(0.15)
        }
    }

    public var isDark: Bool {
        return self == .midnight
    }
}

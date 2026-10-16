import SwiftUI
import Combine

public enum AppTheme: String, CaseIterable, Identifiable {
    case autoDayNight = "autoDayNight"      // Авто: Днем — Винный бархат, Вечером — Полуночный оксфорд
    case wineVelvet = "wineVelvet"          // Винный бархат (Бордо/Марсала)
    case midnightOxford = "midnightOxford"  // Полуночный оксфорд (Индиго/Сапфир)
    case warmAmber = "warmAmber"            // Книжный янтарь (Классика)
    case emerald = "emerald"                // Изумрудный переплет

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .autoDayNight: return "Автосмена"
        case .wineVelvet: return "Винный бархат"
        case .midnightOxford: return "Полуночный оксфорд"
        case .warmAmber: return "Книжный янтарь"
        case .emerald: return "Изумрудный переплёт"
        }
    }

    public var subtitle: String {
        switch self {
        case .autoDayNight: return "С 07:00 до 19:00 благородный бордовый, после 19:00 глубокий ночной индиго"
        case .wineVelvet: return "Глубокие винные и сливовые тона классических переплетов"
        case .midnightOxford: return "Темный чернильный индиго для комфортного чтения в темноте"
        case .warmAmber: return "Теплая янтарно-кофейная гамма с золотистыми акцентами"
        case .emerald: return "Классическая библиотека с зелеными абажурами и золотом"
        }
    }
}

public class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    @Published public var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedAppTheme")
            updateActiveColors()
        }
    }

    @Published public var currentEffectiveTheme: AppTheme = .wineVelvet
    @Published public var primaryAccent: Color = Color(red: 0.55, green: 0.16, blue: 0.22) // Wine
    @Published public var secondaryAccent: Color = Color(red: 0.75, green: 0.35, blue: 0.42)
    @Published public var paperBackground: Color = Color(red: 0.98, green: 0.97, blue: 0.95)
    @Published public var darkPaperBackground: Color = Color(red: 0.10, green: 0.08, blue: 0.09)

    private var timer: Timer?

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedAppTheme"),
           let theme = AppTheme(rawValue: saved) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = .wineVelvet
        }
        updateActiveColors()
        // Таймер для проверки времени суток каждые 5 минут в авто-режиме
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateActiveColors()
        }
    }

    // Адаптивный фон экрана: бумага в светлой теме, глубокий ночной графит в тёмной
    public func paperBackground(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? darkPaperBackground : paperBackground
    }

    // Адаптивная подложка карточек и поверхностей
    public func cardBackground(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : Color.white
    }

    // Тонкий микро-бордер для идеального отделения слоёв в обоих режимах
    public func cardBorder(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
    }

    public func updateActiveColors() {
        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = hour >= 19 || hour < 7

        let effective: AppTheme
        if selectedTheme == .autoDayNight {
            effective = isEvening ? .midnightOxford : .wineVelvet
        } else {
            effective = selectedTheme
        }

        self.currentEffectiveTheme = effective

        switch effective {
        case .wineVelvet:
            // Благородное бордо / Марсала (#7E2231 / #A33A4B)
            self.primaryAccent = Color(red: 0.52, green: 0.14, blue: 0.20)
            self.secondaryAccent = Color(red: 0.74, green: 0.28, blue: 0.36)
            self.paperBackground = Color(red: 0.98, green: 0.96, blue: 0.94)
            self.darkPaperBackground = Color(red: 0.11, green: 0.08, blue: 0.09)

        case .midnightOxford:
            // Глубокий Оксфордский индиго / Сапфир (#1E2E4F / #2E4674)
            self.primaryAccent = Color(red: 0.20, green: 0.32, blue: 0.54)
            self.secondaryAccent = Color(red: 0.32, green: 0.48, blue: 0.74)
            self.paperBackground = Color(red: 0.95, green: 0.96, blue: 0.98)
            self.darkPaperBackground = Color(red: 0.07, green: 0.09, blue: 0.13)

        case .warmAmber:
            // Классический янтарь (#D9531E / #F38230)
            self.primaryAccent = Color(red: 0.88, green: 0.35, blue: 0.12)
            self.secondaryAccent = Color(red: 0.96, green: 0.54, blue: 0.22)
            self.paperBackground = Color(red: 0.98, green: 0.97, blue: 0.94)
            self.darkPaperBackground = Color(red: 0.12, green: 0.09, blue: 0.07)

        case .emerald:
            // Изумрудный переплет (#1A4D38 / #2B7255)
            self.primaryAccent = Color(red: 0.14, green: 0.40, blue: 0.29)
            self.secondaryAccent = Color(red: 0.24, green: 0.58, blue: 0.42)
            self.paperBackground = Color(red: 0.95, green: 0.98, blue: 0.96)
            self.darkPaperBackground = Color(red: 0.07, green: 0.11, blue: 0.09)

        case .autoDayNight:
            break
        }
    }
}

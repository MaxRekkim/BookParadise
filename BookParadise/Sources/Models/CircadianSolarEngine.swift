import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Photobiological Circadian Phase
public enum CircadianSolarPhase: String, CaseIterable, Identifiable, Codable {
    case daylight = "Дневной зенит (6500K)"
    case goldenHour = "Золотой час (4500K)"
    case twilight = "Сумерки (3000K)"
    case candlelight = "Свечное пламя (1800K)"
    case rubyDark = "Рубиновая ночь (630nm)"
    
    public var id: String { rawValue }
    
    public var kelvin: Int {
        switch self {
        case .daylight: return 6500
        case .goldenHour: return 4500
        case .twilight: return 3000
        case .candlelight: return 1800
        case .rubyDark: return 1000 // Monochromatic ruby indicator
        }
    }
    
    public var icon: String {
        switch self {
        case .daylight: return "sun.max.fill"
        case .goldenHour: return "sun.horizon.fill"
        case .twilight: return "sunset.fill"
        case .candlelight: return "flame.fill"
        case .rubyDark: return "moon.stars.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .daylight:
            return "Максимальный контраст и нейтральный спектр для глубокого аналитического чтения."
        case .goldenHour:
            return "Мягкий медовый оттенок с теплой диффузией света конца дня."
        case .twilight:
            return "Снижение синего диапазона спектра (460 нм) для снятия зрительного напряжения."
        case .candlelight:
            return "Теплый янтарный оттенок живого пламени без возбуждения зрительных рецепторов."
        case .rubyDark:
            return "Монохроматический рубиновый спектр 630 нм на истинном OLED-черном для сохранения родопсина."
        }
    }
    
    public var melatoninProtectionScore: Double {
        switch self {
        case .daylight: return 0.15
        case .goldenHour: return 0.50
        case .twilight: return 0.75
        case .candlelight: return 0.92
        case .rubyDark: return 0.99
        }
    }
    
    public var pageBackgroundColor: Color {
        switch self {
        case .daylight:
            return Color(UIColor.systemBackground)
        case .goldenHour:
            return Color(red: 0.98, green: 0.95, blue: 0.88)
        case .twilight:
            return Color(red: 0.93, green: 0.88, blue: 0.80)
        case .candlelight:
            return Color(red: 0.20, green: 0.13, blue: 0.08)
        case .rubyDark:
            return Color.black
        }
    }
    
    public var textColor: Color {
        switch self {
        case .daylight:
            return Color(UIColor.label)
        case .goldenHour:
            return Color(red: 0.18, green: 0.14, blue: 0.10)
        case .twilight:
            return Color(red: 0.22, green: 0.18, blue: 0.15)
        case .candlelight:
            return Color(red: 0.96, green: 0.82, blue: 0.65)
        case .rubyDark:
            return Color(red: 0.95, green: 0.15, blue: 0.15)
        }
    }
    
    public var accentTint: Color {
        switch self {
        case .daylight:
            return Color.blue
        case .goldenHour:
            return Color.orange
        case .twilight:
            return Color(red: 0.85, green: 0.55, blue: 0.35)
        case .candlelight:
            return Color(red: 0.98, green: 0.60, blue: 0.20)
        case .rubyDark:
            return Color(red: 0.90, green: 0.10, blue: 0.10)
        }
    }
}

// MARK: - Circadian Astronomical Solar Reading Engine
public final class CircadianSolarEngine: ObservableObject {
    public static let shared = CircadianSolarEngine()
    
    @Published public var isAutoAstronomicalEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isAutoAstronomicalEnabled, forKey: "Circadian_AutoEnabled")
            if isAutoAstronomicalEnabled {
                updateSolarPhaseForCurrentTime()
            }
        }
    }
    
    @Published public var currentPhase: CircadianSolarPhase = .daylight {
        didSet {
            UserDefaults.standard.set(currentPhase.rawValue, forKey: "Circadian_CurrentPhase")
        }
    }
    
    @Published public var simulatedHour: Double = 12.0
    @Published public var solarElevationDegrees: Double = 45.0
    @Published public var blueLightAttenuationFactor: Double = 0.0
    
    private var timer: AnyCancellable?
    
    private init() {
        self.isAutoAstronomicalEnabled = UserDefaults.standard.object(forKey: "Circadian_AutoEnabled") as? Bool ?? true
        if let savedPhase = UserDefaults.standard.string(forKey: "Circadian_CurrentPhase"),
           let phase = CircadianSolarPhase(rawValue: savedPhase) {
            self.currentPhase = phase
        } else {
            self.currentPhase = .daylight
        }
        
        updateSolarPhaseForCurrentTime()
        
        // Start recurring refresh every 15 minutes
        self.timer = Timer.publish(every: 900, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isAutoAstronomicalEnabled else { return }
                self.updateSolarPhaseForCurrentTime()
            }
    }
    
    // MARK: - Astronomical Solar Elevation Approximation
    public func calculateSolarElevation(hourOfDay: Double) -> Double {
        // Simplified solar diurnal curve:
        // 00:00 -> -50° (Deep Nadir)
        // 06:00 -> 0° (Dawn Horizon)
        // 12:00 -> +55° (Zenith Noon)
        // 18:00 -> 0° (Dusk Horizon)
        // 21:00 -> -25° (Twilight/Night)
        let normalizedAngle = ((hourOfDay - 6.0) / 24.0) * (2.0 * Double.pi)
        let elevation = sin(normalizedAngle) * 55.0
        return elevation
    }
    
    public func resolvePhase(forHour hour: Double) -> CircadianSolarPhase {
        if hour >= 22.5 || hour < 5.5 {
            return .rubyDark
        } else if hour >= 20.0 || (hour >= 5.5 && hour < 6.5) {
            return .candlelight
        } else if (hour >= 18.0 && hour < 20.0) || (hour >= 6.5 && hour < 7.5) {
            return .twilight
        } else if (hour >= 16.0 && hour < 18.0) || (hour >= 7.5 && hour < 9.0) {
            return .goldenHour
        } else {
            return .daylight
        }
    }
    
    public func updateSolarPhaseForCurrentTime() {
        let calendar = Calendar.current
        let now = Date()
        let hour = Double(calendar.component(.hour, from: now)) + Double(calendar.component(.minute, from: now)) / 60.0
        self.simulatedHour = hour
        self.solarElevationDegrees = calculateSolarElevation(hourOfDay: hour)
        self.currentPhase = resolvePhase(forHour: hour)
        self.blueLightAttenuationFactor = currentPhase.melatoninProtectionScore
    }
    
    public func setManualPhase(_ phase: CircadianSolarPhase) {
        self.isAutoAstronomicalEnabled = false
        self.currentPhase = phase
        self.blueLightAttenuationFactor = phase.melatoninProtectionScore
        switch phase {
        case .daylight: self.simulatedHour = 12.0
        case .goldenHour: self.simulatedHour = 17.0
        case .twilight: self.simulatedHour = 19.0
        case .candlelight: self.simulatedHour = 21.0
        case .rubyDark: self.simulatedHour = 23.5
        }
        self.solarElevationDegrees = calculateSolarElevation(hourOfDay: simulatedHour)
    }
}

import SwiftUI

/// Палитра и текстурный шейдер бумаги (PaperTextureKit)
/// Воссоздает тактильные визуальные свойства различных видов бумаги и режим истинного OLED.
public enum PaperTextureType: String, CaseIterable, Identifiable {
    case antiqueParchment = "antiqueParchment" // Антикварный пергамент
    case japaneseWashi = "japaneseWashi"       // Японская бумага васи
    case classicWhite = "classicWhite"         // Белоснежная типографская бумага
    case sepiaComfort = "sepiaComfort"         // Золотистая теплая сепия
    case oledMidnight = "oledMidnight"         // Абсолютный ночной OLED (0% энергопотребления на черном)

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .antiqueParchment: return "Антикварный пергамент"
        case .japaneseWashi: return "Японская бумага «Васи»"
        case .classicWhite: return "Типографский лист"
        case .sepiaComfort: return "Уютная сепия"
        case .oledMidnight: return "Полуночный OLED"
        }
    }

    public var description: String {
        switch self {
        case .antiqueParchment: return "Тёплый винтажный оттенок старинных фолиантов"
        case .japaneseWashi: return "Нежный молочный тон с мягкой органической текстурой"
        case .classicWhite: return "Четкий высокий контраст современной верстки"
        case .sepiaComfort: return "Снижает нагрузку на глаза при длительном чтении"
        case .oledMidnight: return "Истинный черный #000000 для чтения в полной темноте"
        }
    }

    public var backgroundColor: Color {
        switch self {
        case .antiqueParchment:
            return Color(red: 0.96, green: 0.93, blue: 0.86)
        case .japaneseWashi:
            return Color(red: 0.97, green: 0.96, blue: 0.93)
        case .classicWhite:
            return Color(red: 0.99, green: 0.99, blue: 0.99)
        case .sepiaComfort:
            return Color(red: 0.94, green: 0.89, blue: 0.80)
        case .oledMidnight:
            return Color.black
        }
    }

    public var textColor: Color {
        switch self {
        case .antiqueParchment:
            return Color(red: 0.18, green: 0.14, blue: 0.10)
        case .japaneseWashi:
            return Color(red: 0.16, green: 0.15, blue: 0.14)
        case .classicWhite:
            return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .sepiaComfort:
            return Color(red: 0.22, green: 0.16, blue: 0.10)
        case .oledMidnight:
            // Мягкий неслепящий белый цвет (88% яркости) против смазывания пикселей при скролле
            return Color(red: 0.86, green: 0.86, blue: 0.87)
        }
    }

    public var spineShadowColor: Color {
        switch self {
        case .oledMidnight:
            return Color.white.opacity(0.08)
        default:
            return Color.black.opacity(0.18)
        }
    }

    public var isDarkMode: Bool {
        return self == .oledMidnight
    }
}

/// Адаптивный визуальный модификатор фона для читалки с микротекстурой
public struct PaperTextureViewModifier: ViewModifier {
    public let texture: PaperTextureType

    public func body(content: Content) -> some View {
        ZStack {
            texture.backgroundColor
                .ignoresSafeArea()

            // Процедурный шум / текстура бумаги для не-OLED режимов
            if !texture.isDarkMode {
                PaperNoiseOverlay()
                    .opacity(0.035)
                    .ignoresSafeArea()
            }

            content
        }
    }
}

/// Микросетка шума, имитирующая волокна бумаги
public struct PaperNoiseOverlay: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            // Рендерим тончайшие волокна
            let step: CGFloat = 8.0
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    let hash = sin(x * 12.9898 + y * 78.233) * 43758.5453
                    let isFiber = hash.truncatingRemainder(dividingBy: 1.0) > 0.88
                    if isFiber {
                        let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                        context.fill(Path(rect), with: .color(Color.black.opacity(0.4)))
                    }
                    x += step
                }
                y += step
            }
        }
    }
}

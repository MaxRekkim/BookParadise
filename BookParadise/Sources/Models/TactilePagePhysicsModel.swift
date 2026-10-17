import Foundation
import CoreGraphics
import SwiftUI

/// Направление интерактивного перелистывания страницы
public enum PageFlipDirection: String, CaseIterable, Identifiable {
    case forward = "forward"     // Вперед (перелистывание правой страницы налево)
    case backward = "backward"   // Назад (перелистывание левой страницы направо)

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .forward: return "Следующая страница"
        case .backward: return "Предыдущая страница"
        }
    }
}

/// Плотность и сорт книжной бумаги для расчета физики и акустики
public enum PaperWeight: String, CaseIterable, Identifiable {
    case lightweight = "lightweight" // Папиросная / рисовая бумага (шелестящая)
    case standard = "standard"       // Классический книжный офсет 80 г/м²
    case heavyVerge = "heavyVerge"   // Плотный верже / веленевая бумага 120 г/м²

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .lightweight: return "Тонкая бумага (шелковистый шелест)"
        case .standard: return "Классический офсет 80г/м²"
        case .heavyVerge: return "Тяжелый верже 120г/м² (глухой шуршащий тон)"
        }
    }

    public var hapticIntensity: Double {
        switch self {
        case .lightweight: return 0.4
        case .standard: return 0.7
        case .heavyVerge: return 1.0
        }
    }

    public var basePitchMultiplier: Float {
        switch self {
        case .lightweight: return 1.45
        case .standard: return 1.0
        case .heavyVerge: return 0.72
        }
    }
}

/// Математическая модель скевоморфной 3D-физики листания бумаги (Tactile Page Physics Model)
/// Вычисляет нелинейный угол прогиба листа, оптическую тень под изгибом и световой блик.
public struct TactilePagePhysicsModel: Equatable {
    public var dragProgress: CGFloat // 0.0 (закрыта) ... 1.0 (полностью перевернута)
    public var direction: PageFlipDirection
    public var paperWeight: PaperWeight
    public var containerWidth: CGFloat

    public init(
        dragProgress: CGFloat = 0.0,
        direction: PageFlipDirection = .forward,
        paperWeight: PaperWeight = .standard,
        containerWidth: CGFloat = 400.0
    ) {
        self.dragProgress = max(0.0, min(1.0, dragProgress))
        self.direction = direction
        self.paperWeight = paperWeight
        self.containerWidth = max(100.0, containerWidth)
    }

    /// Угол 3D-вращения листа вокруг корешка книги (от 0° до ±180°)
    public var rotationAngle: Double {
        let normalized = Double(dragProgress)
        // Нелинейная кривая для естественного ощущения сопротивления бумаги
        let curved = pow(normalized, 0.92)
        switch direction {
        case .forward:
            return -curved * 180.0
        case .backward:
            return 180.0 - (1.0 - curved) * 180.0
        }
    }

    /// Преодолела ли страница критический порог (35%), после которого она захлопнется вперед
    public var isPastThreshold: Bool {
        return dragProgress >= 0.35
    }

    /// Интенсивность тени под приподнятым краем листа (максимум на 90°)
    public var shadowOpacity: Double {
        let rad = Double(dragProgress) * .pi
        let rawSine = sin(rad)
        let weightFactor: Double = {
            switch paperWeight {
            case .lightweight: return 0.28
            case .standard: return 0.42
            case .heavyVerge: return 0.58
            }
        }()
        return rawSine * weightFactor
    }

    /// Ширина рассеивания тени в точках (pt)
    public var shadowWidth: CGFloat {
        let rad = CGFloat(dragProgress) * .pi
        let maxSpread: CGFloat = paperWeight == .heavyVerge ? 42.0 : 32.0
        return max(4.0, sin(rad) * maxSpread)
    }

    /// Интенсивность зеркального цилиндрического блика света вдоль гребня изгиба
    public var specularHighlightOpacity: Double {
        let rad = Double(dragProgress) * .pi
        return sin(rad) * 0.22
    }

    /// Смещение гребня цилиндра изгиба страницы
    public var curlCrestOffset: CGFloat {
        let halfWidth = containerWidth / 2.0
        let progress = dragProgress
        return (1.0 - progress) * halfWidth
    }

    /// Обратная сторона страницы активна (угол превысил 90 градусов)
    public var isShowingReverseSide: Bool {
        return abs(rotationAngle) >= 90.0
    }
}

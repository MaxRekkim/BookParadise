import Foundation

/// Движок бинауральных волн и алгоритмического затухания звука (Binaural Focus Engine)
/// Синтезирует разность частот для синхронизации полушарий мозга во время глубокого чтения.
public struct BinauralFocusEngine {

    public enum BrainwaveBand: String, CaseIterable, Identifiable {
        case gamma = "gamma" // 40 Гц — Пиковая концентрация и анализ сложных книг
        case alpha = "alpha" // 10 Гц — Состояние потока, расслабленное и быстрое чтение
        case theta = "theta" // 6 Гц — Художественное погружение и воображение
        case delta = "delta" // 2.5 Гц — Вечернее чтение перед сном

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .gamma: return "Гамма-ритм (40 Гц)"
            case .alpha: return "Альфа-ритм (10 Гц)"
            case .theta: return "Тета-ритм (6 Гц)"
            case .delta: return "Дельта-ритм (2.5 Гц)"
            }
        }

        public var subtitle: String {
            switch self {
            case .gamma: return "Высокая концентрация для научпопа, философии и учебы"
            case .alpha: return "Состояние когнитивного потока без усталости"
            case .theta: return "Яркие образы и эмоциональный резонанс с сюжетом"
            case .delta: return "Успокоение нервной системы и чтение перед сном"
            }
        }

        public var baseFrequency: Double {
            switch self {
            case .gamma: return 240.0 // Несущая частота левого уха
            case .alpha: return 210.0
            case .theta: return 180.0
            case .delta: return 140.0
            }
        }

        public var beatFrequency: Double {
            switch self {
            case .gamma: return 40.0
            case .alpha: return 10.0
            case .theta: return 6.0
            case .delta: return 2.5
            }
        }

        public var rightEarFrequency: Double {
            return baseFrequency + beatFrequency
        }
    }

    /// Рассчитывает экспоненциальное затухание громкости таймера сна
    /// V(t) = V0 * (1 - (t / T)^1.5)
    /// Это предотвращает резкий обрыв звука, позволяя мозгу плавно перейти ко сну.
    public static func calculateFadeVolume(
        initialVolume: Float,
        elapsedSeconds: TimeInterval,
        totalDurationSeconds: TimeInterval
    ) -> Float {
        guard totalDurationSeconds > 0 else { return 0.0 }
        let progress = min(1.0, max(0.0, elapsedSeconds / totalDurationSeconds))
        
        // Экспоненциально-плавная кривая восприятия человеческим слухом
        let volumeFactor = Float(pow(1.0 - progress, 1.6))
        return max(0.0, min(initialVolume, initialVolume * volumeFactor))
    }
}

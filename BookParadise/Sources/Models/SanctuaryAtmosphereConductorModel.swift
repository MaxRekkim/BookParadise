import Foundation
import SwiftUI

// MARK: - Пресеты пространственного звукового ландшафта 4.0
public enum SanctuarySoundscapePreset: String, CaseIterable, Identifiable, Codable {
    case alexandriaLibrary = "Александрийская библиотека"
    case atticRain = "Шёпот дождя на чердаке"
    case monasticCell = "Келья древнего монастыря"
    case alpineCabin = "Альпийская хижина в горах"
    case midnightFireplace = "Камин в ночной тишине"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .alexandriaLibrary: return "building.columns.fill"
        case .atticRain: return "cloud.rain.fill"
        case .monasticCell: return "candle.fill"
        case .alpineCabin: return "mountain.2.fill"
        case .midnightFireplace: return "flame.fill"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .alexandriaLibrary: return "Мягкое эхо мраморных залов и шуршание папируса"
        case .atticRain: return "Мерный стук капель по черепице и далекие раскаты грома"
        case .monasticCell: return "Тихий треск свечи и абсолютная акустическая тишина"
        case .alpineCabin: return "Ветер в соснах за окном и лёгкое потрескивание дров"
        case .midnightFireplace: return "Глубокое теплое гудение пламени и изоляция от мира"
        }
    }
    
    public var baseFrequenciesHz: (rain: Double, wood: Double, resonance: Double) {
        switch self {
        case .alexandriaLibrary: return (0.1, 0.0, 0.6)
        case .atticRain: return (0.8, 0.2, 0.1)
        case .monasticCell: return (0.0, 0.05, 0.4)
        case .alpineCabin: return (0.3, 0.5, 0.2)
        case .midnightFireplace: return (0.0, 0.8, 0.3)
        }
    }
}

// MARK: - Состояние акустического дирижера (Conductor State)
public struct SanctuaryAtmosphereState: Identifiable, Codable, Equatable {
    public let id: UUID
    public var activePreset: SanctuarySoundscapePreset
    public var masterVolume: Double
    public var spatialBinauralWidth: Double // 0.0 (Mono) ... 1.0 (Full 3D)
    public var isPlaying: Bool
    public var pageTurnAcousticFeedback: Bool
    
    public init(
        id: UUID = UUID(),
        activePreset: SanctuarySoundscapePreset = .atticRain,
        masterVolume: Double = 0.65,
        spatialBinauralWidth: Double = 0.85,
        isPlaying: Bool = false,
        pageTurnAcousticFeedback: Bool = true
    ) {
        self.id = id
        self.activePreset = activePreset
        self.masterVolume = masterVolume
        self.spatialBinauralWidth = spatialBinauralWidth
        self.isPlaying = isPlaying
        self.pageTurnAcousticFeedback = pageTurnAcousticFeedback
    }
    
    public mutating func togglePlayback() {
        self.isPlaying.toggle()
    }
    
    public static var defaultState: SanctuaryAtmosphereState {
        SanctuaryAtmosphereState()
    }
}

import Foundation
import SwiftUI

// MARK: - Зона когнитивного потока (Flow Zone)
public enum CognitiveFlowZone: String, CaseIterable, Identifiable, Codable {
    case flow = "Глубокий Поток (Flow)"
    case deepImmersion = "Погружение"
    case lightSkimming = "Беглый просмотр"
    case recoveryZone = "Зона отдыха"
    
    public var id: String { rawValue }
    
    public var badgeColor: Color {
        switch self {
        case .flow: return .purple
        case .deepImmersion: return .blue
        case .lightSkimming: return .orange
        case .recoveryZone: return .green
        }
    }
    
    public var iconName: String {
        switch self {
        case .flow: return "brain.head.profile"
        case .deepImmersion: return "waveform.path.ecg"
        case .lightSkimming: return "eye.fill"
        case .recoveryZone: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Метрики когнитивного состояния
public struct CognitiveFlowMetrics: Equatable, Codable {
    public var flowScore: Double // 0 ... 100
    public var focusMinutesStreak: Int
    public var currentZone: CognitiveFlowZone
    public var paceStabilityPercent: Double
    public var eyeStrainAlertNeeded: Bool
    
    public init(
        flowScore: Double = 88.0,
        focusMinutesStreak: Int = 42,
        currentZone: CognitiveFlowZone = .flow,
        paceStabilityPercent: Double = 94.0,
        eyeStrainAlertNeeded: Bool = false
    ) {
        self.flowScore = flowScore
        self.focusMinutesStreak = focusMinutesStreak
        self.currentZone = currentZone
        self.paceStabilityPercent = paceStabilityPercent
        self.eyeStrainAlertNeeded = eyeStrainAlertNeeded
    }
}

// MARK: - Движок вычисления резонанса и потока
public struct CognitiveFlowEngine {
    
    public static func evaluateFlow(sessionDurationMinutes: Int, averageSpeedPPH: Double, pauseCount: Int) -> CognitiveFlowMetrics {
        guard sessionDurationMinutes > 0 else {
            return CognitiveFlowMetrics(flowScore: 0, focusMinutesStreak: 0, currentZone: .recoveryZone, paceStabilityPercent: 100, eyeStrainAlertNeeded: false)
        }
        
        // Чем меньше пауз на единицу времени, тем выше стабильность
        let stability = max(20.0, 100.0 - (Double(pauseCount) * 12.0))
        
        // Базовый расчет балла потока
        let durationBonus = min(Double(sessionDurationMinutes) * 1.5, 45.0)
        let speedBonus = min(averageSpeedPPH * 0.8, 35.0)
        let stabilityBonus = (stability / 100.0) * 20.0
        
        let score = min(100.0, durationBonus + speedBonus + stabilityBonus)
        
        let zone: CognitiveFlowZone
        if score >= 80 {
            zone = .flow
        } else if score >= 55 {
            zone = .deepImmersion
        } else if score >= 30 {
            zone = .lightSkimming
        } else {
            zone = .recoveryZone
        }
        
        let eyeStrain = sessionDurationMinutes >= 50
        
        return CognitiveFlowMetrics(
            flowScore: score,
            focusMinutesStreak: sessionDurationMinutes,
            currentZone: zone,
            paceStabilityPercent: stability,
            eyeStrainAlertNeeded: eyeStrain
        )
    }
}

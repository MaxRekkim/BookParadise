import Foundation
import SwiftUI

// MARK: - Читательский хронотип
public enum ReaderChronotype: String, Codable, CaseIterable {
    case morningLark = "Утренний жаворонок"
    case afternoonThinker = "Полуденный мыслитель"
    case eveningContemplator = "Вечерний созерцатель"
    case nightPhilosopher = "Ночной философ (Сова)"
    
    public var iconName: String {
        switch self {
        case .morningLark: return "sunrise.fill"
        case .afternoonThinker: return "sun.max.fill"
        case .eveningContemplator: return "sunset.fill"
        case .nightPhilosopher: return "moon.stars.fill"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .morningLark: return .orange
        case .afternoonThinker: return .yellow
        case .eveningContemplator: return .purple
        case .nightPhilosopher: return .indigo
        }
    }
    
    public var optimalWindowAdvice: String {
        switch self {
        case .morningLark:
            return "Ваш мозг максимально восприимчив к сложной нон-фикшн литературе и философии в первые часы после пробуждения (06:00–09:00)."
        case .afternoonThinker:
            return "Идеальное время для глубоких исторических исследований и аналитических эссе в обеденный перерыв (12:00–15:00)."
        case .eveningContemplator:
            return "Вечернее время идеально для погружения в многослойную художественную прозу и поэзию (18:00–21:00)."
        case .nightPhilosopher:
            return "В ночной тишине обостряется восприятие мистического реализма, метафизики и экзистенциальной драмы (22:00–02:00)."
        }
    }
}

// MARK: - Профиль циркадного ритма чтения
public struct ReadingCircadianProfile: Equatable {
    public var morningRatio: Double
    public var afternoonRatio: Double
    public var eveningRatio: Double
    public var nightRatio: Double
    public var dominantChronotype: ReaderChronotype
    public var peakHourString: String
    
    public init(
        morningRatio: Double = 0.15,
        afternoonRatio: Double = 0.20,
        eveningRatio: Double = 0.25,
        nightRatio: Double = 0.40,
        dominantChronotype: ReaderChronotype = .nightPhilosopher,
        peakHourString: String = "23:00"
    ) {
        self.morningRatio = morningRatio
        self.afternoonRatio = afternoonRatio
        self.eveningRatio = eveningRatio
        self.nightRatio = nightRatio
        self.dominantChronotype = dominantChronotype
        self.peakHourString = peakHourString
    }
}

// MARK: - Анализатор циркадных ритмов (ReadingChronotypeEngine)
public struct ReadingChronotypeEngine {
    
    public static func analyzeSessionHours(_ hours: [Int]) -> ReadingCircadianProfile {
        guard !hours.isEmpty else {
            return ReadingCircadianProfile()
        }
        
        var m = 0, a = 0, e = 0, n = 0
        for h in hours {
            switch h {
            case 5..<11: m += 1
            case 11..<17: a += 1
            case 17..<22: e += 1
            default: n += 1
            }
        }
        
        let total = Double(hours.count)
        let mRatio = Double(m) / total
        let aRatio = Double(a) / total
        let eRatio = Double(e) / total
        let nRatio = Double(n) / total
        
        let maxVal = max(mRatio, max(aRatio, max(eRatio, nRatio)))
        let dominant: ReaderChronotype
        if maxVal == mRatio { dominant = .morningLark }
        else if maxVal == aRatio { dominant = .afternoonThinker }
        else if maxVal == eRatio { dominant = .eveningContemplator }
        else { dominant = .nightPhilosopher }
        
        return ReadingCircadianProfile(
            morningRatio: mRatio,
            afternoonRatio: aRatio,
            eveningRatio: eRatio,
            nightRatio: nRatio,
            dominantChronotype: dominant,
            peakHourString: dominant == .nightPhilosopher ? "23:00" : "08:00"
        )
    }
}

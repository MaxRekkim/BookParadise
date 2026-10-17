import Foundation
import SwiftUI

@MainActor
public class RPGLevelManager: ObservableObject {
    public static let shared = RPGLevelManager()
    private let storageKey = "BookParadise_RPG_State_v1"

    @Published public private(set) var state: RPGState

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(RPGState.self, from: data) {
            self.state = decoded
        } else {
            self.state = RPGState()
        }
    }

    public var totalXP: Int { state.totalXP }

    // MARK: - Расчет уровней
    // Формула: каждый уровень требует базовые 300 XP + (уровень * 150)
    public func xpRequired(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        var total = 0
        for lvl in 1..<level {
            total += 300 + (lvl * 150)
        }
        return total
    }

    public var currentLevel: Int {
        var level = 1
        while state.totalXP >= xpRequired(for: level + 1) {
            level += 1
            if level >= 50 { break }
        }
        return level
    }

    public var xpForCurrentLevelBase: Int {
        return xpRequired(for: currentLevel)
    }

    public var xpForNextLevelTarget: Int {
        return xpRequired(for: currentLevel + 1)
    }

    public var currentLevelXPProgress: Int {
        return max(0, state.totalXP - xpForCurrentLevelBase)
    }

    public var currentLevelXPSpan: Int {
        return max(1, xpForNextLevelTarget - xpForCurrentLevelBase)
    }

    public var progressPercent: Double {
        return min(1.0, Double(currentLevelXPProgress) / Double(currentLevelXPSpan))
    }

    public var currentRankTitle: String {
        return currentRank.title
    }

    public func awardXP(_ amount: Int, reason: String = "") {
        addXP(amount, reason: reason)
    }

    public func resetProgress() {
        state.totalXP = 0
        state.unlockedPerks.removeAll()
        save()
    }

    public var currentRank: RPGRankInfo {
        let lvl = currentLevel
        switch lvl {
        case 1..<3:
            return RPGRankInfo(
                level: lvl,
                title: "Любознательный Новичок",
                icon: "leaf.fill",
                color: .green,
                perkDescription: "Первые шаги в бескрайнем книжном океане."
            )
        case 3..<5:
            return RPGRankInfo(
                level: lvl,
                title: "Вдумчивый Читатель",
                icon: "book.fill",
                color: .teal,
                perkDescription: "Чтение становится приятной ежедневной привычкой."
            )
        case 5..<8:
            return RPGRankInfo(
                level: lvl,
                title: "Книжный Червь",
                icon: "sparkles",
                color: .blue,
                perkDescription: "Способен погружаться в сюжет на часы без перерыва."
            )
        case 8..<12:
            return RPGRankInfo(
                level: lvl,
                title: "Хранитель Фолиантов",
                icon: "shield.lefthalf.filled",
                color: Color(red: 0.52, green: 0.14, blue: 0.20), // Wine
                perkDescription: "Библиотека обретает масштаб настоящей сокровищницы."
            )
        case 12..<16:
            return RPGRankInfo(
                level: lvl,
                title: "Охотник за Смыслами",
                icon: "flame.fill",
                color: .orange,
                perkDescription: "Видит скрытые параллели и глубинный подтекст авторов."
            )
        case 16..<20:
            return RPGRankInfo(
                level: lvl,
                title: "Библиомант",
                icon: "wand.and.stars",
                color: .purple,
                perkDescription: "Владеет редким даром интуитивного выбора великих книг."
            )
        default:
            return RPGRankInfo(
                level: lvl,
                title: "Магистр Слова",
                icon: "crown.fill",
                color: .yellow,
                perkDescription: "Легендарный статус. Истинный повелитель литературы."
            )
        }
    }

    // MARK: - Начисление опыта
    public func addXP(_ amount: Int, reason: String = "") {
        guard amount > 0 else { return }
        let prevLevel = currentLevel
        state.totalXP += amount
        save()

        if currentLevel > prevLevel {
            HapticManager.shared.levelUp()
        } else {
            HapticManager.shared.lightTap()
        }
    }

    public func syncWithLibrary(books: [Book], sessionsCount: Int, quotesCount: Int) {
        // Подсчет исторического опыта из существующих книг
        let pagesXP = books.reduce(0) { $0 + ($1.pagesRead * 2) }
        let finishedXP = books.filter { $0.status == .read }.count * 150
        let sessionsXP = sessionsCount * 25
        let quotesXP = quotesCount * 15

        let calculatedMinimumXP = pagesXP + finishedXP + sessionsXP + quotesXP
        if calculatedMinimumXP > state.totalXP {
            state.totalXP = calculatedMinimumXP
            save()
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}

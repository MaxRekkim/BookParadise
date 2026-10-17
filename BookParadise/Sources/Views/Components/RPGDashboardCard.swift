import SwiftUI

public struct RPGDashboardCard: View {
    @ObservedObject private var rpg = RPGLevelManager.shared
    @ObservedObject private var streakMgr = StreakManager.shared
    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // Верхняя плашка: Ранг и Стрик
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(rpg.currentRank.color.opacity(0.15))
                            .frame(width: 42, height: 42)
                        Image(systemName: rpg.currentRank.icon)
                            .font(.system(size: 20))
                            .foregroundColor(rpg.currentRank.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("УРОВЕНЬ \(rpg.currentLevel)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(rpg.currentRank.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(rpg.currentRank.color.opacity(0.12))
                                .clipShape(Capsule())

                            Text(rpg.currentRank.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                        }

                        Text(rpg.currentRank.perkDescription)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Стрик-бейдж
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(streakMgr.currentStreak > 0 ? .orange : .secondary)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(streakMgr.currentStreak) дн.")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.primary)
                        Text("стрик")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Шкала опыта (XP)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(rpg.currentLevelXPProgress) / \(rpg.currentLevelXPSpan) XP")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(rpg.progressPercent * 100))%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(rpg.currentRank.color)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [rpg.currentRank.color, rpg.currentRank.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(rpg.progressPercent)))
                    }
                }
                .frame(height: 7)
            }

            // Нижняя строка: Заморозки и статус цели на сегодня
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("Заморозки: \(streakMgr.freezes)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if streakMgr.isCompletedToday {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("Норма дня выполнена!")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Цель: \(streakMgr.targetPages) стр или \(streakMgr.targetMinutes) мин")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rpg.currentRank.color.opacity(0.2), lineWidth: 1)
        )
    }
}

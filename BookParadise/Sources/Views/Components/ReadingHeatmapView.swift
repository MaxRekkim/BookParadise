import SwiftUI

public struct ReadingHeatmapView: View {
    @ObservedObject private var streakMgr = StreakManager.shared
    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init() {}

    private let columns = Array(repeating: GridItem(.fixed(14), spacing: 4), count: 7)
    private let dayLabels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(wineAccent)
                Text("ТЕПЛОВАЯ КАРТА ЧТЕНИЯ")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(streakMgr.streak.activeDates.count) активных дней")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(wineAccent)
            }

            // Дни недели
            HStack(spacing: 4) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 14, alignment: .center)
                }
            }

            // Сетка последних 35 дней (5 недель)
            let pastDays = getPastDays(count: 35)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(pastDays, id: \.self) { day in
                    let isActive = streakMgr.isDateActive(day)
                    let isToday = Calendar.current.isDateInToday(day)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isActive ? wineAccent : Color.secondary.opacity(0.15))
                        .frame(width: 14, height: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(isToday ? Color.primary : Color.clear, lineWidth: 1)
                        )
                }
            }

            // Легенда
            HStack(spacing: 8) {
                Text("Меньше")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.15)).frame(width: 9, height: 9)
                    RoundedRectangle(cornerRadius: 2).fill(wineAccent.opacity(0.4)).frame(width: 9, height: 9)
                    RoundedRectangle(cornerRadius: 2).fill(wineAccent.opacity(0.7)).frame(width: 9, height: 9)
                    RoundedRectangle(cornerRadius: 2).fill(wineAccent).frame(width: 9, height: 9)
                }

                Text("Больше")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 3) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    Text("Пик: 21:00–23:00")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func getPastDays(count: Int) -> [Date] {
        let calendar = Calendar.current
        var days: [Date] = []
        let today = Date()

        for offset in (0..<count).reversed() {
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                days.append(date)
            }
        }
        return days
    }
}

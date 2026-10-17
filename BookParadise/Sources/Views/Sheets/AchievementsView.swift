import SwiftUI

public struct AchievementsView: View {
    @ObservedObject private var achievementManager = AchievementManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: AchievementCategory? = nil
    public var onDismiss: (() -> Void)? = nil

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    private func handleDismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
        #if canImport(UIKit)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .dismiss(animated: true, completion: nil)
        #endif
    }

    private var filteredAchievements: [ReadingAchievement] {
        if let cat = selectedCategory {
            return achievementManager.achievements.filter { $0.category == cat }
        }
        return achievementManager.achievements
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.paperBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Карточка стрика и щита защиты
                        streakAndShieldBanner
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        // Категории фильтров
                        categoryFilterChips
                            .padding(.horizontal, 16)

                        // Сетка эмалевых значков
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredAchievements) { item in
                                achievementCard(item: item)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Трофеи и привычки (\(achievementManager.unlockedCount)/\(achievementManager.totalCount))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { handleDismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryAccent)
                        .keyboardShortcut(.cancelAction)
                }
            }
            .onExitCommand {
                handleDismiss()
            }
            .interactiveDismissDisabled(false)
            .onAppear {
                achievementManager.recalculateAll()
            }
        }
    }

    // MARK: - Баннер Стрика и Щита Защиты
    private var streakAndShieldBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.orange.opacity(0.4), radius: 6, x: 0, y: 3)

                    Text("\(achievementManager.currentStreak)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Текущий стрик чтения")
                            .font(.headline)
                            .fontWeight(.bold)
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                    }

                    Text(achievementManager.currentStreak == 0
                         ? "Начните читать сегодня, чтобы зажечь книжный огонь!"
                         : "Вы читаете уже \(achievementManager.currentStreak) дн. подряд без перерыва!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(achievementManager.streakShields > 0 ? .blue : .secondary)
                    Text("Щит защиты стрика:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    ForEach(0..<2) { idx in
                        Image(systemName: idx < achievementManager.streakShields ? "shield.fill" : "shield")
                            .font(.caption)
                            .foregroundColor(idx < achievementManager.streakShields ? .blue : .secondary.opacity(0.4))
                    }
                    Text(achievementManager.streakShields > 0 ? "\(achievementManager.streakShields) в запасе" : "Использован")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(achievementManager.streakShields > 0 ? .blue : .secondary)
                }
            }

            if achievementManager.isShieldActiveToday {
                HStack(spacing: 6) {
                    Image(systemName: "umbrella.fill")
                        .foregroundColor(.purple)
                    Text("Вчера был день отдыха — стрик защищен и сохранен!")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    // MARK: - Чипы категорий
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "Все", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(AchievementCategory.allCases) { cat in
                    categoryChip(title: cat.title, icon: cat.icon, isSelected: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
        }
    }

    private func categoryChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? theme.primaryAccent : theme.cardBackground(for: colorScheme))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? theme.primaryAccent : theme.cardBorder(for: colorScheme), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Карточка эмалированного значка
    private func achievementCard(item: ReadingAchievement) -> some View {
        VStack(spacing: 12) {
            // Эмалевый медальон
            ZStack {
                Circle()
                    .fill(
                        item.isUnlocked
                        ? LinearGradient(colors: [Color.yellow.opacity(0.3), theme.primaryAccent.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 68, height: 68)

                Circle()
                    .stroke(
                        item.isUnlocked
                        ? LinearGradient(colors: [Color(red: 0.95, green: 0.80, blue: 0.40), Color(red: 0.80, green: 0.55, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.4)], startPoint: .top, endPoint: .bottom),
                        lineWidth: item.isUnlocked ? 2.5 : 1
                    )
                    .frame(width: 68, height: 68)

                if item.isUnlocked {
                    Text(item.badgeEmoji)
                        .font(.system(size: 32))
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.top, 4)

            VStack(spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(item.isUnlocked ? Color(UIColor.label) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 28)
            }

            // Прогресс
            if !item.isUnlocked {
                VStack(spacing: 4) {
                    ProgressView(value: item.progress, total: 1.0)
                        .tint(theme.primaryAccent)
                        .frame(height: 5)

                    Text(item.progressText)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                    Text("Разблокировано")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.isUnlocked ? theme.primaryAccent.opacity(0.25) : theme.cardBorder(for: colorScheme), lineWidth: item.isUnlocked ? 1.5 : 0.8)
        )
        .shadow(color: item.isUnlocked ? theme.primaryAccent.opacity(0.08) : Color.clear, radius: 6, x: 0, y: 3)
    }
}

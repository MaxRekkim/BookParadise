import SwiftUI
import WidgetKit

#if canImport(UIKit)
import UIKit
#endif

/// Интерактивная панель разработчика и диагностики для отладки всех подсистем v3.1.0
public struct DebugDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var streakManager = StreakManager.shared
    @ObservedObject private var rpgManager = RPGLevelManager.shared
    @ObservedObject private var soundManager = SoundscapeManager.shared
    
    @State private var consoleLogs: [String] = []
    @State private var showingResetAlert = false
    @State private var activeTab = 0
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Вкладки разделов диагностики
                Picker("Раздел", selection: $activeTab) {
                    Text("RPG & Стрик").tag(0)
                    Text("Аудио & Виджеты").tag(1)
                    Text("Система & Логи").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                ScrollView {
                    VStack(spacing: 18) {
                        switch activeTab {
                        case 0:
                            rpgAndStreakSection
                        case 1:
                            audioAndWidgetsSection
                        default:
                            systemAndLogsSection
                        }
                    }
                    .padding()
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("🛠️ Панель диагностики")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                appendLog("Панель разработчика запущена. Среда: \(getEnvironmentString())")
            }
        }
    }
    
    // MARK: - 1. RPG & Streak
    private var rpgAndStreakSection: some View {
        VStack(spacing: 16) {
            // Карточка RPG
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("RPG Уровень & Опыт")
                        .font(.headline)
                    Spacer()
                    Text("Ур. \(rpgManager.currentLevel)")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ранг: \(rpgManager.currentRankTitle)")
                            .font(.subheadline)
                        Text("Всего XP: \(rpgManager.totalXP)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Прогресс: \(rpgManager.currentLevelXPProgress) / \(rpgManager.currentLevelXPSpan) XP (\(Int(rpgManager.progressPercent * 100))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                ProgressView(value: rpgManager.progressPercent)
                    .tint(.yellow)
                
                // Кнопки управления RPG
                HStack(spacing: 8) {
                    Button("+100 XP") {
                        rpgManager.awardXP(100, reason: "Debug test +100")
                        appendLog("Начислено +100 XP. Итого: \(rpgManager.totalXP)")
                    }
                    .buttonStyle(.bordered)
                    .tint(.yellow)
                    
                    Button("+500 XP (Up)") {
                        rpgManager.awardXP(500, reason: "Debug test +500")
                        appendLog("Начислено +500 XP. Уровень: \(rpgManager.currentLevel)")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    
                    Button("Сброс") {
                        rpgManager.resetProgress()
                        appendLog("RPG прогресс сброшен в 0.")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .font(.footnote)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            
            // Карточка Стриков
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Стрик-система (Серия дней)")
                        .font(.headline)
                    Spacer()
                    Text("\(streakManager.currentStreak) дн.")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Рекорд серии: \(streakManager.bestStreak) дн.")
                            .font(.subheadline)
                        Text("Заморозок доступно: \(streakManager.freezesAvailable) / 2 ❄️")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let last = streakManager.lastActiveDate {
                            Text("Посл. чтение: \(last.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Посл. чтение: нет")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                
                // Кнопки управления стриком
                HStack(spacing: 8) {
                    Button("Отметить сегодня") {
                        streakManager.recordReadingToday()
                        appendLog("Записано чтение сегодня. Стрик: \(streakManager.currentStreak)")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    
                    Button("+1 ❄️ Заморозка") {
                        streakManager.restoreFreeze()
                        appendLog("Добавлена заморозка. Доступно: \(streakManager.freezesAvailable)")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button("Сброс") {
                        streakManager.resetStreak()
                        appendLog("Стрик сброшен.")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .font(.footnote)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
    }
    
    // MARK: - 2. Audio & Widgets
    private var audioAndWidgetsSection: some View {
        VStack(spacing: 16) {
            // Аудио микшер
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.indigo)
                    Text("Atmosphere Studio 2.0")
                        .font(.headline)
                    Spacer()
                    Text(soundManager.isPlaying ? "АКТИВЕН" : "СТОП")
                        .font(.caption)
                        .bold()
                        .foregroundColor(soundManager.isPlaying ? .green : .secondary)
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Дождь")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(soundManager.rainVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Камин")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(soundManager.fireplaceVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Кофейня")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(soundManager.coffeehouseVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Лес")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(soundManager.forestVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    Button(soundManager.isPlaying ? "Остановить" : "Включить") {
                        if soundManager.isPlaying {
                            soundManager.stop()
                            appendLog("Аудио микшер остановлен.")
                        } else {
                            soundManager.setMode(.coffeehouse)
                            appendLog("Включен режим «Кофейня».")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    
                    Button("Дождь") {
                        soundManager.setMode(.rain)
                        appendLog("Включен режим «Дождь».")
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)
                    
                    Button("Камин") {
                        soundManager.setMode(.fireplace)
                        appendLog("Включен режим «Камин».")
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)
                }
                .font(.footnote)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            
            // Виджеты
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "square.dashed")
                        .foregroundColor(.purple)
                    Text("Синхронизация виджетов (WidgetKit)")
                        .font(.headline)
                }
                
                Divider()
                
                Text("App Group: group.com.maxim.bookparadise")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    WidgetCenter.shared.reloadAllTimelines()
                    appendLog("Таймлайны WidgetKit принудительно перезагружены.")
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Перезагрузить таймлайны виджетов")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
    }
    
    // MARK: - 3. System & Logs
    private var systemAndLogsSection: some View {
        VStack(spacing: 16) {
            // Системные сведения
            VStack(alignment: .leading, spacing: 8) {
                Text("Системное окружение")
                    .font(.headline)
                Divider()
                
                LabeledContent("Платформа", value: getPlatformString())
                LabeledContent("Версия ОС", value: UIDevice.current.systemVersion)
                LabeledContent("Модель", value: UIDevice.current.model)
                LabeledContent("Бандл", value: Bundle.main.bundleIdentifier ?? "н/д")
                LabeledContent("Версия приложения", value: "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "32"))")
            }
            .font(.subheadline)
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            
            // Лог-консоль
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Консоль отладки")
                        .font(.headline)
                    Spacer()
                    Button("Очистить") {
                        consoleLogs.removeAll()
                    }
                    .font(.caption)
                }
                
                Divider()
                
                if consoleLogs.isEmpty {
                    Text("Логи чисты...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(consoleLogs, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
        }
    }
    
    private func appendLog(_ msg: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        consoleLogs.insert("[\(timestamp)] \(msg)", at: 0)
        if consoleLogs.count > 50 {
            consoleLogs.removeLast()
        }
    }
    
    private func getPlatformString() -> String {
        #if targetEnvironment(macCatalyst)
        return "macOS (Mac Catalyst)"
        #elseif os(iOS)
        return "iOS Native"
        #else
        return "Unknown"
        #endif
    }
    
    private func getEnvironmentString() -> String {
        #if DEBUG
        return "DEBUG"
        #else
        return "RELEASE"
        #endif
    }
}

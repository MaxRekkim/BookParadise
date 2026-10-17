import SwiftUI
import UIKit

/// Представительский Кабинет Библиофила: объединяет личный профиль, экслибрис, аудио-атмосферу,
/// ночной режим StandBy, суверенное хранилище, экспорт/импорт и настройки святилища.
public struct SanctuaryCabinetView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var soundscape = SoundscapeManager.shared
    @ObservedObject private var achievementManager = AchievementManager.shared
    @ObservedObject private var updateManager = UpdateManager.shared
    @ObservedObject private var solarEngine = CircadianSolarEngine.shared

    // Модальные окна инструментов
    @State private var isShowingStandByClock: Bool = false
    @State private var isShowingSoundscapeMixer: Bool = false
    @State private var isShowingOracle: Bool = false
    @State private var isShowingAchievements: Bool = false
    @State private var isShowingAlmanac: Bool = false
    @State private var isShowingNeuroPacer: Bool = false
    @State private var isShowingSettings: Bool = false
    @State private var isShowingSovereignVault: Bool = false
    @State private var isShowingObsidianSync: Bool = false
    @State private var isShowingImporter: Bool = false
    @State private var isShowingExLibrisStudio: Bool = false
    @State private var isShowingCircadianSolar: Bool = false
    @State private var isShowingCognitiveDensity: Bool = false

    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Представительский мастер-баннер Святилища
                    SanctuaryMasterOverviewView()
                        .padding(.horizontal)

                    // 2. Инструменты чтения и атмосфера
                    sanctuaryToolsSection
                        .padding(.horizontal)

                    // 3. Суверенитет данных и синхронизация
                    dataSovereigntySection
                        .padding(.horizontal)

                    // 4. Оформление и системные настройки
                    preferencesSection
                        .padding(.horizontal)

                    // 5. Подвал с версией и проверкой обновлений
                    footerSection
                        .padding(.horizontal)
                        .padding(.bottom, 90)
                }
                .padding(.top, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Кабинет Библиофила")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.primaryAccent)
                    }
                    .accessibilityLabel("Настройки")
                }
            }
            .sheet(isPresented: $isShowingStandByClock) {
                StandByNightstandClockView(
                    currentBook: viewModel.readingNowBooks.first,
                    onDismiss: { isShowingStandByClock = false }
                )
            }
            .sheet(isPresented: $isShowingSoundscapeMixer) {
                SoundscapeMixerSheet()
                    .macSheetFrame()
            }
            .sheet(isPresented: $isShowingOracle) {
                BookOracleView(viewModel: viewModel, onDismiss: { isShowingOracle = false })
                    .macSheetFrame()
            }
            .sheet(isPresented: $isShowingAchievements) {
                AchievementsView()
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingAlmanac) {
                ReadingAlmanacPreviewView()
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingNeuroPacer) {
                BionicNeuroPacerView(
                    text: "Чтение расширяет границы разума и открывает новые горизонты мышления для каждого читателя.",
                    bookTitle: "Книжный Рай"
                )
                .macSheetFrame()
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(viewModel: viewModel)
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingSovereignVault) {
                NavigationStack {
                    SovereignVaultSecurityView()
                        .navigationTitle("Суверенное хранилище")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Готово") { isShowingSovereignVault = false }
                            }
                        }
                }
                .macSheetFrame()
            }
            .sheet(isPresented: $isShowingObsidianSync) {
                NavigationStack {
                    ObsidianVaultSyncView()
                        .navigationTitle("Obsidian Vault")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Готово") { isShowingObsidianSync = false }
                            }
                        }
                }
                .macSheetFrame()
            }
            .sheet(isPresented: $isShowingImporter) {
                NavigationStack {
                    UniversalLibraryImporterView()
                        .navigationTitle("Универсальный импорт")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Готово") { isShowingImporter = false }
                            }
                        }
                }
                .macSheetFrame()
            }
            .sheet(isPresented: $isShowingExLibrisStudio) {
                ExLibrisStudioSheet()
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingCircadianSolar) {
                CircadianSolarControlSheet()
                    .macSheetFrame()
            }
            .sheet(isPresented: $isShowingCognitiveDensity) {
                let textSample = viewModel.books.map { "\($0.title). \($0.author). \($0.genre.rawValue)." }.joined(separator: " ")
                let result = ShannonEntropyEngine.shared.analyze(text: textSample.isEmpty ? "Книжный Рай: Библиотека библиофила и суверенное святилище мысли." : textSample)
                CognitiveDensitySheet(result: result)
                    .macSheetFrame()
            }
        }
    }

    // MARK: - Секция инструментов и атмосферы
    private var sanctuaryToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ИНСТРУМЕНТЫ ЧИТАТЕЛЬСКОГО СВЯТИЛИЩА")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .tracking(1.2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                cabinetToolCard(
                    title: "Прикроватный StandBy",
                    subtitle: "Ночные OLED-часы 1800K",
                    icon: "bed.double.fill",
                    color: .orange
                ) {
                    isShowingStandByClock = true
                    HapticManager.shared.lightTap()
                }

                cabinetToolCard(
                    title: "Аудио-ландшафты",
                    subtitle: soundscape.isPlaying ? "Активен звук" : "Дождь, камин, библиотека",
                    icon: soundscape.isPlaying ? "waveform" : "headphones",
                    color: soundscape.isPlaying ? theme.primaryAccent : .indigo
                ) {
                    isShowingSoundscapeMixer = true
                    HapticManager.shared.lightTap()
                }

                cabinetToolCard(
                    title: "Книжный Оракул",
                    subtitle: "Интеллектуальный выбор",
                    icon: "sparkles",
                    color: .purple
                ) {
                    isShowingOracle = true
                    HapticManager.shared.lightTap()
                }

                cabinetToolCard(
                    title: "Литературный Пантеон",
                    subtitle: "\(achievementManager.unlockedCount) трофеев получено",
                    icon: "trophy.fill",
                    color: .yellow
                ) {
                    isShowingAchievements = true
                    HapticManager.shared.lightTap()
                }

                cabinetToolCard(
                    title: "Альманах года",
                    subtitle: "Подарочный PDF буклет",
                    icon: "book.pages.fill",
                    color: .teal
                ) {
                    isShowingAlmanac = true
                    HapticManager.shared.lightTap()
                }

                cabinetToolCard(
                    title: "Bionic NeuroPacer",
                    subtitle: "Фокусировка саккад глаз",
                    icon: "eye.fill",
                    color: .blue
                ) {
                    isShowingNeuroPacer = true
                    HapticManager.shared.lightTap()
                }

                cabinetToolCard(
                    title: "Мастерская экслибриса",
                    subtitle: "Личный книжный знак и форзац",
                    icon: "seal.fill",
                    color: Color(red: 0.85, green: 0.68, blue: 0.28)
                ) {
                    isShowingExLibrisStudio = true
                    HapticManager.shared.lightTap()
                }

                cabinetToolCard(
                    title: "Циркадный свет",
                    subtitle: "\(solarEngine.currentPhase.rawValue)",
                    icon: solarEngine.currentPhase.icon,
                    color: solarEngine.currentPhase.accentTint
                ) {
                    isShowingCircadianSolar = true
                    HapticManager.shared.lightTap()
                }
            }
        }
    }

    // MARK: - Секция суверенитета данных
    private var dataSovereigntySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("СУВЕРЕНИТЕТ ДАННЫХ И ЭКСПОРТ")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .tracking(1.2)

            VStack(spacing: 8) {
                cabinetListRow(
                    title: "Суверенное хранилище (Zero-Cloud)",
                    subtitle: "Локальная БД, SHA-256 верификация",
                    icon: "lock.shield.fill",
                    iconColor: .green
                ) {
                    isShowingSovereignVault = true
                }

                Divider().padding(.leading, 44)

                cabinetListRow(
                    title: "Obsidian Vault Sync",
                    subtitle: "Двусторонняя синхронизация заметок и вики-ссылок",
                    icon: "link.badge.plus",
                    iconColor: .purple
                ) {
                    isShowingObsidianSync = true
                }

                Divider().padding(.leading, 44)

                cabinetListRow(
                    title: "Универсальный импорт данных",
                    subtitle: "Goodreads, LiveLib, CSV таблицы",
                    icon: "square.and.arrow.down.fill",
                    iconColor: .blue
                ) {
                    isShowingImporter = true
                }

                Divider().padding(.leading, 44)

                cabinetListRow(
                    title: "Энтропия Шеннона и когнитивная плотность",
                    subtitle: "H(X), лексический анализ TTR и метрики сложности",
                    icon: "atom",
                    iconColor: .pink
                ) {
                    isShowingCognitiveDensity = true
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Секция настроек и тем
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ОФОРМЛЕНИЕ И СИСТЕМА")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .tracking(1.2)

            VStack(spacing: 8) {
                cabinetListRow(
                    title: "Настройки приложения",
                    subtitle: "Темы оформления, иконка, параметры чтения",
                    icon: "gearshape.fill",
                    iconColor: theme.primaryAccent
                ) {
                    isShowingSettings = true
                }
            }
            .padding(14)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    // MARK: - Подвал
    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("Книжный Рай — Суверенное святилище")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("Версия \(updateManager.currentVersion) (Build 44)")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    // MARK: - Вспомогательные компоненты
    private func cabinetToolCard(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func cabinetListRow(title: String, subtitle: String, icon: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI
import UniformTypeIdentifiers

public struct SettingsView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var cloudSync = iCloudSyncManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("kindleEmail") private var kindleEmail: String = ""
    @State private var webAppURL: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var testResultMessage: String? = nil
    @State private var isSuccess: Bool = false
    @State private var cacheSizeText: String = ""
    
    @State private var exportURL: URL? = nil
    @State private var isShowingImporter: Bool = false
    @State private var importAlertMessage: String? = nil
    @State private var isShowingImportAlert: Bool = false
    public var onDismiss: (() -> Void)? = nil
    
    public init(viewModel: LibraryViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
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
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Оформление
                Section(header: Text("Оформление")) {
                    ForEach(AppTheme.allCases) { item in
                        Button(action: {
                            theme.selectedTheme = item
                        }) {
                            HStack(spacing: 12) {
                                // Превью цвета
                                themeColorCircle(for: item)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    if item == .autoDayNight {
                                        Text("Сейчас активно: \(theme.currentEffectiveTheme == .wineVelvet ? "Дневной (Бордо)" : "Ночной (Индиго)")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if theme.selectedTheme == item {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(theme.primaryAccent)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - Отправка на Kindle
                Section(header: Text("Отправка на Kindle"), footer: Text("Укажите email вашей читалки (например, имя@kindle.com). Не забудьте добавить вашу личную почту в доверенный список на Amazon.")) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(theme.primaryAccent)
                        TextField("имя@kindle.com", text: $kindleEmail)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        if !kindleEmail.isEmpty {
                            Button(action: { kindleEmail = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // MARK: - Облачная синхронизация
                Section(header: Text("Облачная синхронизация"), footer: Text("Вставьте URL веб-приложения для синхронизации (заканчивается на /exec).")) {
                    HStack {
                        TextField("https://script.google.com/macros/s/.../exec", text: $webAppURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        if !webAppURL.isEmpty {
                            Button(action: { webAppURL = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Button(action: testAndSaveConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .padding(.trailing, 6)
                            } else {
                                Image(systemName: "network")
                            }
                            Text("Проверить и сохранить связь")
                        }
                        .fontWeight(.semibold)
                    }
                    .disabled(webAppURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTestingConnection)
                    
                    if let msg = testResultMessage {
                        HStack {
                            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(isSuccess ? .green : .red)
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(isSuccess ? .green : .red)
                        }
                    }
                }
                
                // MARK: - Синхронизация
                Section(header: Text("Синхронизация")) {
                    HStack {
                        Text("Статус:")
                        Spacer()
                        if viewModel.isSyncing {
                            HStack(spacing: 6) {
                                ProgressView()
                                Text("Синхронизация...")
                                    .font(.caption)
                                    .foregroundColor(theme.primaryAccent)
                            }
                        } else if GoogleSheetsAPIService.shared.isConfigured {
                            Text("Подключено")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        } else {
                            Text("Автономный режим (Демо-база)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let lastSync = viewModel.lastSyncDate {
                        HStack {
                            Text("Последняя синхронизация:")
                            Spacer()
                            Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        Task { await viewModel.syncWithCloud() }
                    }) {
                        HStack(spacing: 8) {
                            if viewModel.isSyncing {
                                ThinkingOrbView(state: .working, size: 18)
                                Text("Синхронизация с облаком...")
                            } else {
                                Image(systemName: "arrow.clockwise")
                                Text("Принудительно синхронизировать сейчас")
                            }
                        }
                    }
                    .disabled(viewModel.isSyncing || !GoogleSheetsAPIService.shared.isConfigured)
                }
                
                Section(header: Text("О приложении")) {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.1")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Сборка")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Синхронизация между устройствами (iCloud & Бэкапы)
                Section(header: Text("Синхронизация между устройствами (iCloud)"), footer: Text("Автоматически синхронизирует библиотеку между вашим iPhone, iPad и Mac через личный iCloud.")) {
                    HStack {
                        Image(systemName: cloudSync.isICloudAvailable ? "icloud.fill" : "icloud.slash")
                            .foregroundColor(cloudSync.isICloudAvailable ? .blue : .secondary)
                        Text("Статус:")
                        Spacer()
                        Text(cloudSync.syncStatusMessage)
                            .font(.caption)
                            .foregroundColor(cloudSync.isICloudAvailable ? .primary : .secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    if let exportURL = exportURL {
                        ShareLink(item: exportURL, preview: SharePreview("Резервная копия Книжный Рай", image: Image(systemName: "books.vertical.fill"))) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Поделиться бэкапом (AirDrop / Файлы)")
                            }
                            .foregroundColor(theme.primaryAccent)
                        }
                    } else {
                        Button(action: generateBackupFile) {
                            HStack {
                                Image(systemName: "arrow.down.doc")
                                Text("Экспортировать резервную копию")
                            }
                        }
                    }
                    
                    Button(action: { isShowingImporter = true }) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                            Text("Импортировать базу из файла")
                        }
                    }
                }

                // MARK: - Экспорт в Markdown (Obsidian / Notion)
                Section(header: Text("Экспорт в Markdown (Obsidian / Notion)"), footer: Text("Экспортирует весь каталог ваших книг и цитаты в сводный файл Markdown для вашей персональной базы знаний (PKM).")) {
                    if let catalogFile = generateCatalogMarkdownFile() {
                        ShareLink(item: catalogFile, preview: SharePreview("Каталог_Книжный_Рай.md", image: Image(systemName: "books.vertical.fill"))) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("Экспортировать каталог в Markdown (.md)")
                            }
                            .foregroundColor(theme.primaryAccent)
                        }
                    }
                }
                
                Section(header: Text("Локальные данные и кэш")) {
                    HStack {
                        Text("Кэш обложек на диске")
                        Spacer()
                        Text(cacheSizeText)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: clearCoverCache) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Очистить кэш обложек")
                        }
                        .foregroundColor(.red)
                    }
                    
                    Button(role: .destructive, action: resetToDefaultSample) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Сбросить к эталонным 327 книгам")
                        }
                    }
                }
            }
            .navigationTitle("Настройки")
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
            .fileImporter(
                isPresented: $isShowingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let fileURL = urls.first {
                        do {
                            let imported = try iCloudSyncManager.shared.importBackup(from: fileURL)
                            viewModel.books = imported.books
                            viewModel.bingoItems = imported.bingo
                            viewModel.recalculateStats()
                            viewModel.persistData()
                            importAlertMessage = "Успешно импортировано книг: \(imported.books.count)"
                            isShowingImportAlert = true
                        } catch {
                            importAlertMessage = "Ошибка импорта: \(error.localizedDescription)"
                            isShowingImportAlert = true
                        }
                    }
                case .failure(let error):
                    importAlertMessage = "Ошибка выбора файла: \(error.localizedDescription)"
                    isShowingImportAlert = true
                }
            }
            .alert("Резервная копия", isPresented: $isShowingImportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importAlertMessage ?? "")
            }
            .onAppear {
                webAppURL = GoogleSheetsAPIService.shared.apiURLString
                cacheSizeText = ImageCacheManager.shared.formattedCacheSize()
                cloudSync.checkICloudStatus()
            }
        }
    }
    
    @ViewBuilder
    private func themeColorCircle(for item: AppTheme) -> some View {
        switch item {
        case .autoDayNight:
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.52, green: 0.14, blue: 0.20), Color(red: 0.16, green: 0.25, blue: 0.44)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 24, height: 24)
        case .wineVelvet:
            Circle()
                .fill(Color(red: 0.52, green: 0.14, blue: 0.20))
                .frame(width: 24, height: 24)
        case .midnightOxford:
            Circle()
                .fill(Color(red: 0.16, green: 0.25, blue: 0.44))
                .frame(width: 24, height: 24)
        case .warmAmber:
            Circle()
                .fill(Color(red: 0.88, green: 0.35, blue: 0.12))
                .frame(width: 24, height: 24)
        case .emerald:
            Circle()
                .fill(Color(red: 0.11, green: 0.33, blue: 0.24))
                .frame(width: 24, height: 24)
        }
    }
    
    private func testAndSaveConnection() {
        let cleanURL = webAppURL.trimmingCharacters(in: .whitespacesAndNewlines)
        GoogleSheetsAPIService.shared.apiURLString = cleanURL
        
        isTestingConnection = true
        testResultMessage = nil
        
        Task {
            do {
                let result = try await GoogleSheetsAPIService.shared.fetchLibrary()
                await MainActor.run {
                    self.isTestingConnection = false
                    self.isSuccess = true
                    self.testResultMessage = "Успешно! Загружено \(result.books.count) книг из таблицы."
                    self.viewModel.books = result.books
                    if !result.bingo.isEmpty { self.viewModel.bingoItems = result.bingo }
                }
            } catch {
                await MainActor.run {
                    self.isTestingConnection = false
                    self.isSuccess = false
                    self.testResultMessage = "Ошибка соединения: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func clearCoverCache() {
        ImageCacheManager.shared.clearAllCache()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            cacheSizeText = ImageCacheManager.shared.formattedCacheSize()
        }
    }
    
    private func generateBackupFile() {
        self.exportURL = iCloudSyncManager.shared.createExportFileURL(books: viewModel.books, bingo: viewModel.bingoItems)
    }
    
    private func resetToDefaultSample() {
        viewModel.books = SampleData.generateInitialBooks()
        viewModel.bingoItems = SampleData.generateInitialBingo()
        GoogleSheetsAPIService.shared.saveToLocalCache(books: viewModel.books, bingo: viewModel.bingoItems)
        viewModel.loadInitialData()
    }

    private func generateCatalogMarkdownFile() -> URL? {
        let md = MarkdownExportService.shared.exportCatalogToMarkdown(books: viewModel.books, quotes: QuotesManager.shared.quotes)
        return MarkdownExportService.shared.createTemporaryMarkdownFile(content: md, filename: "Каталог_Книжный_Рай")
    }
}

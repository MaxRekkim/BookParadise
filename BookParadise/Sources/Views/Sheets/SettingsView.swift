import SwiftUI

public struct SettingsView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var webAppURL: String = ""
    @State private var isTestingConnection: Bool = false
    @State private var testResultMessage: String? = nil
    @State private var isSuccess: Bool = false
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Google Таблица («✨📚КНИЖНЫЙ РАЙ📚✨»)"), footer: Text("Вставьте URL веб-приложения Google Apps Script (заканчивается на /exec).")) {
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
                
                Section(header: Text("Синхронизация")) {
                    HStack {
                        Text("Статус:")
                        Spacer()
                        if viewModel.isSyncing {
                            HStack(spacing: 6) {
                                ProgressView()
                                Text("Синхронизация...")
                                    .font(.caption)
                                    .foregroundColor(.orange)
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
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Принудительно синхронизировать сейчас")
                        }
                    }
                    .disabled(viewModel.isSyncing || !GoogleSheetsAPIService.shared.isConfigured)
                }
                
                Section(header: Text("Инструкция по настройке Google Таблицы")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Откройте таблицу «✨📚КНИЖНЫЙ РАЙ📚✨» в Google Chrome.")
                            .font(.caption)
                        Text("2. Меню: Расширения -> Apps Script.")
                            .font(.caption)
                        Text("3. Вставьте готовый код из файла Code.gs.")
                            .font(.caption)
                        Text("4. Нажмите «Развернуть» -> «Новое развертывание» -> тип «Веб-приложение».")
                            .font(.caption)
                        Text("5. Доступ: «Все» (Anyone), выполнить от имени: «Я».")
                            .font(.caption)
                        Text("6. Скопируйте полученную ссылку и вставьте в поле выше.")
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Локальные данные")) {
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
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear {
                webAppURL = GoogleSheetsAPIService.shared.apiURLString
            }
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
    
    private func resetToDefaultSample() {
        viewModel.books = SampleData.generateInitialBooks()
        viewModel.bingoItems = SampleData.generateInitialBingo()
        GoogleSheetsAPIService.shared.saveToLocalCache(books: viewModel.books, bingo: viewModel.bingoItems)
        viewModel.loadInitialData()
    }
}

import Foundation
import Combine
import SwiftUI

public struct FullLibraryBackup: Codable {
    public var version: String = "2.0.1"
    public var exportedAt: Date = Date()
    public var books: [Book]
    public var bingo: [BingoItem]
    
    public init(books: [Book], bingo: [BingoItem]) {
        self.books = books
        self.bingo = bingo
    }
}

@MainActor
public final class iCloudSyncManager: ObservableObject {
    public static let shared = iCloudSyncManager()
    
    private let localFileName = "BookParadiseDatabase.json"
    private let iCloudFolderName = "BookParadise"
    
    @Published public var isICloudAvailable: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncDate: Date? = nil
    @Published public var syncStatusMessage: String = "Готово"
    
    private var localFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(localFileName)
    }
    
    private var iCloudContainerURL: URL? {
        guard let url = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return nil
        }
        let folder = url.appendingPathComponent("Documents", isDirectory: true).appendingPathComponent(iCloudFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent(localFileName)
    }
    
    private init() {
        checkICloudStatus()
        observeExternalChanges()
    }
    
    public func checkICloudStatus() {
        let token = FileManager.default.ubiquityIdentityToken
        self.isICloudAvailable = (token != nil)
        if isICloudAvailable {
            self.syncStatusMessage = "iCloud активен (автоматическая синхронизация)"
        } else {
            self.syncStatusMessage = "Локальный автономный режим (iCloud выключен)"
        }
    }
    
    private func observeExternalChanges() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleRemoteChange()
            }
        }
    }
    
    private func handleRemoteChange() {
        self.lastSyncDate = Date()
        self.syncStatusMessage = "Обновлено из iCloud"
    }
    
    // MARK: - Сохранение данных (Local-First + iCloud Mirror)
    public func save(books: [Book], bingo: [BingoItem]) {
        let backup = FullLibraryBackup(books: books, bingo: bingo)
        
        // 1. Атомарное сохранение в локальный защищенный файл
        do {
            let data = try JSONEncoder().encode(backup)
            try data.write(to: localFileURL, options: [.atomic, .completeFileProtection])
            
            // Запоминаем timestamp последнего изменения
            NSUbiquitousKeyValueStore.default.set(Date().timeIntervalSince1970, forKey: "lastLibraryUpdateTimestamp")
            NSUbiquitousKeyValueStore.default.synchronize()
        } catch {
            print("Failed to save local database: \(error)")
        }
        
        // 2. Зеркалирование в iCloud Container при доступности
        if let cloudURL = iCloudContainerURL {
            DispatchQueue.global(qos: .utility).async {
                do {
                    let data = try JSONEncoder().encode(backup)
                    try data.write(to: cloudURL, options: [.atomic])
                    DispatchQueue.main.async {
                        self.lastSyncDate = Date()
                        self.syncStatusMessage = "Синхронизировано с iCloud"
                    }
                } catch {
                    print("Failed to mirror to iCloud: \(error)")
                }
            }
        }
    }
    
    // MARK: - Загрузка данных (с проверкой более свежей копии в iCloud)
    public func load() -> (books: [Book], bingo: [BingoItem])? {
        var result: FullLibraryBackup?
        
        // Проверяем iCloud
        if let cloudURL = iCloudContainerURL, FileManager.default.fileExists(atPath: cloudURL.path) {
            do {
                let cloudData = try Data(contentsOf: cloudURL)
                let cloudBackup = try JSONDecoder().decode(FullLibraryBackup.self, from: cloudData)
                result = cloudBackup
                // Обновляем локальный кэш
                try? cloudData.write(to: localFileURL, options: [.atomic, .completeFileProtection])
            } catch {
                print("Failed to read iCloud backup: \(error)")
            }
        }
        
        // Если из iCloud не прочиталось или он недоступен — читаем локальный файл
        if result == nil && FileManager.default.fileExists(atPath: localFileURL.path) {
            do {
                let localData = try Data(contentsOf: localFileURL)
                result = try JSONDecoder().decode(FullLibraryBackup.self, from: localData)
            } catch {
                print("Failed to read local database: \(error)")
            }
        }
        
        if let res = result {
            return (res.books, res.bingo)
        }
        return nil
    }
    
    // MARK: - Экспорт резервной копии (для AirDrop, сохранения в Файлы)
    public func createExportFileURL(books: [Book], bingo: [BingoItem]) -> URL? {
        let backup = FullLibraryBackup(books: books, bingo: bingo)
        do {
            let data = try JSONEncoder().encode(backup)
            let tempDir = FileManager.default.temporaryDirectory
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HHmm"
            let dateStr = formatter.string(from: Date())
            let fileURL = tempDir.appendingPathComponent("BookParadise_Backup_\(dateStr).json")
            try data.write(to: fileURL, options: [.atomic])
            return fileURL
        } catch {
            print("Failed to create export file: \(error)")
            return nil
        }
    }
    
    // MARK: - Импорт резервной копии из внешнего файла
    public func importBackup(from sourceURL: URL) throws -> (books: [Book], bingo: [BingoItem]) {
        let shouldStopAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let data = try Data(contentsOf: sourceURL)
        let backup = try JSONDecoder().decode(FullLibraryBackup.self, from: data)
        save(books: backup.books, bingo: backup.bingo)
        return (backup.books, backup.bingo)
    }
}

import Foundation
import SwiftUI
import UniformTypeIdentifiers

public class EBookStorageManager: ObservableObject {
    public static let shared = EBookStorageManager()
    
    private let fileManager = FileManager.default
    private let storageFolderName = "EBookFiles"
    
    @Published public var storedFilesUpdateTrigger: Int = 0
    
    private var storageDirectoryURL: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        var dir = paths[0].appendingPathComponent(storageFolderName, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? dir.setResourceValues(resourceValues)
        }
        return dir
    }
    
    private init() {}
    
    // MARK: - Проверка наличия файла
    public func hasFile(for bookId: Int) -> Bool {
        return fileURL(for: bookId) != nil
    }
    
    public func fileURL(for bookId: Int) -> URL? {
        guard let files = try? fileManager.contentsOfDirectory(at: storageDirectoryURL, includingPropertiesForKeys: nil) else {
            return nil
        }
        
        let prefix = "book_\(bookId)_"
        return files.first { $0.lastPathComponent.hasPrefix(prefix) }
    }
    
    public func fileDisplayName(for bookId: Int) -> String? {
        guard let url = fileURL(for: bookId) else { return nil }
        let rawName = url.lastPathComponent
        let prefix = "book_\(bookId)_"
        if rawName.hasPrefix(prefix) {
            return String(rawName.dropFirst(prefix.count))
        }
        return rawName
    }
    
    public func fileSizeFormatted(for bookId: Int) -> String? {
        guard let url = fileURL(for: bookId),
              let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    // MARK: - Сохранение файла книги
    @discardableResult
    public func saveBookFile(bookId: Int, from sourceURL: URL) -> URL? {
        removeBookFile(bookId: bookId)
        
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let rawFilename = sourceURL.lastPathComponent
        // Санитизация имени файла от path traversal и спецсимволов
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        let filtered = rawFilename.components(separatedBy: allowedChars.inverted).joined()
        let safeName = filtered.trimmingCharacters(in: CharacterSet(charactersIn: ".")).isEmpty ? "book_file" : filtered
        let destinationURL = storageDirectoryURL.appendingPathComponent("book_\(bookId)_\(safeName)")
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            DispatchQueue.main.async {
                self.storedFilesUpdateTrigger += 1
            }
            return destinationURL
        } catch {
            print("Failed to save book file: \(error)")
            return nil
        }
    }
    
    // MARK: - Удаление файла книги
    public func removeBookFile(bookId: Int) {
        if let existing = fileURL(for: bookId) {
            try? fileManager.removeItem(at: existing)
            DispatchQueue.main.async {
                self.storedFilesUpdateTrigger += 1
            }
        }
    }
}

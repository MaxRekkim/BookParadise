import Foundation
import Combine

public struct SyncResponse: Codable {
    public var success: Bool
    public var message: String?
    public var error: String?
    public var books: [Book]?
    public var bingo: [BingoItem]?
    public var stats: AppStats?
    public var authors: [String]?
    public var editions: [String]?
    public var genres: [String]?
}

public struct PendingAction: Codable, Identifiable {
    public var id: UUID = UUID()
    public var action: String
    public var payload: [String: String]
    public var createdAt: Date = Date()
}

public class GoogleSheetsAPIService: ObservableObject {
    public static let shared = GoogleSheetsAPIService()
    
    private let cacheFileName = "BookParadiseCache.json"
    private let queueFileName = "BookParadiseOfflineQueue.json"
    
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncDate: Date? = nil
    @Published public var lastError: String? = nil
    
    private var pendingQueue: [PendingAction] = []
    
    private init() {
        loadPendingQueue()
    }
    
    // MARK: - URL Настройки
    public var apiURLString: String {
        get {
            UserDefaults.standard.string(forKey: "GoogleAppsScriptURL") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "GoogleAppsScriptURL")
        }
    }
    
    public var isConfigured: Bool {
        return !apiURLString.isEmpty && apiURLString.hasPrefix("https://")
    }
    
    // MARK: - Локальный кэш (Offline First)
    private var cacheFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(cacheFileName)
    }
    
    private var queueFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(queueFileName)
    }
    
    public func saveToLocalCache(books: [Book], bingo: [BingoItem]) {
        let wrapper = CachedDataWrapper(books: books, bingo: bingo, timestamp: Date())
        do {
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: cacheFileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save local cache: \(error)")
        }
    }
    
    public func loadFromLocalCache() -> (books: [Book], bingo: [BingoItem])? {
        guard FileManager.default.fileExists(atPath: cacheFileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: cacheFileURL)
            let wrapper = try JSONDecoder().decode(CachedDataWrapper.self, from: data)
            return (wrapper.books, wrapper.bingo)
        } catch {
            print("Failed to load local cache: \(error)")
            return nil
        }
    }
    
    // MARK: - GET Запрос
    public func fetchLibrary() async throws -> (books: [Book], bingo: [BingoItem], stats: AppStats?) {
        guard isConfigured, let url = URL(string: apiURLString) else {
            throw APIError.missingURL
        }
        
        await MainActor.run { isSyncing = true; lastError = nil }
        defer { Task { @MainActor in isSyncing = false } }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 25
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Код ответа сервера: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        // Проверка: вернул ли сервер HTML (например, страницу входа Google вместо JSON)
        if let responseString = String(data: data, encoding: .utf8) {
            let trimmed = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("<") || trimmed.contains("<!DOCTYPE") || trimmed.contains("<html") {
                if trimmed.contains("accounts.google.com") || trimmed.contains("ServiceLogin") {
                    throw APIError.serverError("Google требует авторизацию! В настройках развертывания веб-приложения выберите: «У кого есть доступ: Все (Anyone)» вместо «Только я».")
                } else if trimmed.contains("ScriptError") || trimmed.contains("Authorization") {
                    throw APIError.serverError("Требуется подтвердить права доступа в Google Apps Script. В редакторе скрипта нажмите «Выполнить» и разрешите доступ.")
                } else {
                    throw APIError.serverError("Google вернул HTML-страницу вместо JSON. Убедитесь, что ссылка заканчивается на /exec и доступ открыт для «Всех».")
                }
            }
        }
        
        let syncResponse: SyncResponse
        do {
            syncResponse = try JSONDecoder().decode(SyncResponse.self, from: data)
        } catch let decodeError {
            throw APIError.serverError("Ошибка разбора данных: \(decodeError.localizedDescription). Проверьте корректность таблицы.")
        }
        
        if !syncResponse.success {
            throw APIError.serverError(syncResponse.error ?? "Неизвестная ошибка Google Apps Script")
        }
        
        let books = syncResponse.books ?? []
        let bingo = syncResponse.bingo ?? []
        
        // Сохраняем в локальный кэш
        saveToLocalCache(books: books, bingo: bingo)
        
        await MainActor.run {
            lastSyncDate = Date()
        }
        
        // После успешного GET сбрасываем накопившуюся очередь оффлайн действий
        processPendingQueue()
        
        return (books, bingo, syncResponse.stats)
    }
    
    // MARK: - POST: Обновление прогресса чтения
    public func postProgressUpdate(bookId: Int, pagesRead: Int, rating: BookRating?) {
        var payload: [String: String] = [
            "action": "updateProgress",
            "id": "\(bookId)",
            "pagesRead": "\(pagesRead)"
        ]
        if let rating = rating {
            payload["rating"] = rating.rawValue
        }
        
        executeOrQueue(action: "updateProgress", payload: payload)
    }
    
    // MARK: - POST: Добавление новой книги
    public func postAddBook(book: Book) {
        let payload: [String: String] = [
            "action": "addBook",
            "title": book.title,
            "author": book.author,
            "edition": book.edition,
            "isbn": book.isbn,
            "cycleNumber": book.cycleNumber,
            "genre": book.genre.rawValue,
            "pagesRead": "\(book.pagesRead)",
            "totalPages": "\(book.totalPages)",
            "format": book.format.rawValue,
            "shelf": book.shelf.rawValue,
            "planMonth": book.planMonth ?? "",
            "rating": book.rating?.rawValue ?? "",
            "cycleName": book.cycleName,
            "coverURL": book.coverURL ?? "",
            "purchaseDate": book.purchaseDate ?? ""
        ]
        
        executeOrQueue(action: "addBook", payload: payload)
    }
    
    // MARK: - POST: Обновление плана
    public func postUpdatePlan(bookId: Int, month: String, planDays: Int) {
        let payload: [String: String] = [
            "action": "updatePlan",
            "id": "\(bookId)",
            "month": month,
            "planDays": "\(planDays)"
        ]
        
        executeOrQueue(action: "updatePlan", payload: payload)
    }
    
    // MARK: - Фоновое выполнение или сохранение в оффлайн-очередь
    private func executeOrQueue(action: String, payload: [String: String]) {
        guard isConfigured, let url = URL(string: apiURLString) else {
            queueAction(action: action, payload: payload)
            return
        }
        
        Task.detached(priority: .background) {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.timeoutInterval = 30
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool, success {
                        print("Sync POST successful for action: \(action)")
                        return
                    }
                }
                
                // Если произошла ошибка сети — ставим в очередь
                await self.enqueuePending(action: action, payload: payload)
            } catch {
                print("Network failed, queuing action: \(action). Error: \(error)")
                await self.enqueuePending(action: action, payload: payload)
            }
        }
    }
    
    @MainActor
    private func enqueuePending(action: String, payload: [String: String]) {
        queueAction(action: action, payload: payload)
    }
    
    private func queueAction(action: String, payload: [String: String]) {
        let item = PendingAction(action: action, payload: payload)
        pendingQueue.append(item)
        savePendingQueue()
    }
    
    private func processPendingQueue() {
        guard !pendingQueue.isEmpty, isConfigured, let url = URL(string: apiURLString) else { return }
        
        let itemsToProcess = pendingQueue
        pendingQueue.removeAll()
        savePendingQueue()
        
        Task.detached(priority: .background) {
            for item in itemsToProcess {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: item.payload)
                    _ = try await URLSession.shared.data(for: request)
                } catch {
                    // Возвращаем в очередь при неудаче
                    await self.enqueuePending(action: item.action, payload: item.payload)
                }
            }
        }
    }
    
    private func savePendingQueue() {
        if let data = try? JSONEncoder().encode(pendingQueue) {
            try? data.write(to: queueFileURL, options: [.atomic, .completeFileProtection])
        }
    }
    
    private func loadPendingQueue() {
        guard FileManager.default.fileExists(atPath: queueFileURL.path),
              let data = try? Data(contentsOf: queueFileURL),
              let items = try? JSONDecoder().decode([PendingAction].self, from: data) else {
            return
        }
        pendingQueue = items
    }
}

private struct CachedDataWrapper: Codable {
    let books: [Book]
    let bingo: [BingoItem]
    let timestamp: Date
}

public enum APIError: LocalizedError {
    case missingURL
    case serverError(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Не указан URL Google Apps Script в настройках"
        case .serverError(let msg):
            return msg
        }
    }
}

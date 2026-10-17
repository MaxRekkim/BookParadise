import Foundation
import SwiftUI
import Combine

@MainActor
public class ReadingNoteStore: ObservableObject {
    public static let shared = ReadingNoteStore()
    
    @Published public var notes: [ReadingNote] = []
    
    private let fileName = "ReadingNotes.json"
    private var fileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    private init() {
        loadNotes()
        if notes.isEmpty {
            createSampleNotes()
        }
    }
    
    // MARK: - CRUD
    public func saveNote(_ note: ReadingNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            var updated = note
            updated.updatedAt = Date()
            notes[idx] = updated
        } else {
            notes.insert(note, at: 0)
        }
        persist()
    }
    
    public func deleteNote(id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }
    
    public func togglePin(id: UUID) {
        if let idx = notes.firstIndex(where: { $0.id == id }) {
            notes[idx].isPinned.toggle()
            persist()
        }
    }
    
    public func notesForBook(bookId: Int) -> [ReadingNote] {
        return notes.filter { $0.bookId == bookId }
    }
    
    public func notes(for bookId: Int) -> [ReadingNote] {
        return notesForBook(bookId: bookId)
    }
    
    public func searchNotes(query: String) -> [ReadingNote] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return notes }
        return notes.filter {
            $0.title.lowercased().contains(q) ||
            $0.content.lowercased().contains(q) ||
            ($0.bookTitle?.lowercased().contains(q) ?? false) ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }
    
    // MARK: - Хранилище
    private func persist() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to persist reading notes: \(error)")
        }
    }
    
    private func loadNotes() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            self.notes = try JSONDecoder().decode([ReadingNote].self, from: data)
        } catch {
            print("Failed to load reading notes: \(error)")
        }
    }
    
    private func createSampleNotes() {
        let sample = ReadingNote(
            title: "Глубокая работа и фокус",
            content: """
            # Размышления о ценности сосредоточенного чтения
            
            > "Способность концентрироваться на трудной задаче без отвлечений — это суперсила XXI века."
            
            ## Ключевые идеи
            - Чтение сложных объемных книг перестраивает нейронные связи в коре мозга.
            - Ежедневный блок в 45 минут без уведомлений дает больший эффект, чем хаотичные попытки читать урывками.
            
            ### Список шагов к идеальной читательской привычке:
            - [x] Отложить телефон в другую комнату перед началом чтения
            - [x] Заварить чай и включить теплый библиотечный свет
            - [ ] Записать главную мысль главы в этот Markdown Studio
            
            💡 **Инсайт**: Чтобы книга осталась в памяти, нужно связать хотя бы один ее тезис с собственным жизненным опытом.
            """,
            tags: ["Инсайт", "Фокус", "Привычки"],
            isPinned: true
        )
        self.notes = [sample]
        persist()
    }
}

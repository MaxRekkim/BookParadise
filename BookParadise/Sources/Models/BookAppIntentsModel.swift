import Foundation
import SwiftUI

// MARK: - Шаблон голосовой команды Siri
public struct BookAppShortcutTemplate: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var triggerPhrase: String
    public var iconName: String
    public var category: String
    public var verbalResponsePreview: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        triggerPhrase: String,
        iconName: String,
        category: String,
        verbalResponsePreview: String
    ) {
        self.id = id
        self.title = title
        self.triggerPhrase = triggerPhrase
        self.iconName = iconName
        self.category = category
        self.verbalResponsePreview = verbalResponsePreview
    }
}

// MARK: - Движок выполнения голосовых команд (AppIntentsExecutionEngine)
public struct AppIntentsExecutionEngine {
    
    public static func executeLogPages(pages: Int, bookTitle: String) -> (success: Bool, message: String) {
        guard pages > 0 else {
            return (false, "Количество страниц должно быть больше нуля.")
        }
        let msg = "Записано \(pages) стр. в «\(bookTitle)». Отличный темп!"
        return (true, msg)
    }
    
    public static func executeStartFocus(minutes: Int, soundscape: String) -> (success: Bool, message: String) {
        let msg = "Фокус-сессия на \(minutes) минут запущена. Включен фоновый звук «\(soundscape)». Приятного чтения!"
        return (true, msg)
    }
    
    public static func executeDailyStatus(pagesToday: Int, streakDays: Int) -> (pagesToday: Int, streak: Int, verbalSnippet: String) {
        let snippet = "Сегодня вы прочитали \(pagesToday) стр. Читательская серия длится \(streakDays) дней подряд! 🔥"
        return (pagesToday, streakDays, snippet)
    }
    
    public static var curatedShortcuts: [BookAppShortcutTemplate] {
        [
            BookAppShortcutTemplate(
                title: "Быстрое логирование",
                triggerPhrase: "«Привет, Siri, запиши чтение в Книжном Рае»",
                iconName: "square.and.pencil",
                category: "Чтение",
                verbalResponsePreview: "Записано 20 страниц в текущую книгу. Читайте с удовольствием!"
            ),
            BookAppShortcutTemplate(
                title: "Фокус-сессия с атмосферой",
                triggerPhrase: "«Привет, Siri, начни фокус-сессию чтения»",
                iconName: "headphones",
                category: "Атмосфера",
                verbalResponsePreview: "Фокус-сессия на 30 минут начата под звуки дождя и камина."
            ),
            BookAppShortcutTemplate(
                title: "Читательский статус дня",
                triggerPhrase: "«Привет, Siri, сколько я сегодня прочитал?»",
                iconName: "flame.fill",
                category: "Статистика",
                verbalResponsePreview: "Сегодня вы прочитали 18 страниц, серия составляет 14 дней подряд!"
            ),
            BookAppShortcutTemplate(
                title: "Книжный Оракул",
                triggerPhrase: "«Привет, Siri, посоветуй книгу из библиотеки»",
                iconName: "sparkles",
                category: "Рекомендации",
                verbalResponsePreview: "Рекомендую открыть «Мастер и Маргарита». Вы остановились на главе 15."
            )
        ]
    }
}

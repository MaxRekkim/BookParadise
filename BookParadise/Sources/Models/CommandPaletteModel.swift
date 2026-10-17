import Foundation
import SwiftUI

/// Категории элементов поисковой командной палитры
public enum CommandPaletteCategory: String, CaseIterable, Identifiable {
    case actions = "actions"       // Быстрые системные действия и инструменты
    case books = "books"           // Каталог книг библиотеки
    case navigation = "navigation" // Разделы приложения
    case quotes = "quotes"         // Литературные цитаты и выписки

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .actions: return "Действия"
        case .books: return "Книги"
        case .navigation: return "Разделы"
        case .quotes: return "Цитаты"
        }
    }

    public var icon: String {
        switch self {
        case .actions: return "bolt.fill"
        case .books: return "book.closed.fill"
        case .navigation: return "arrow.triangle.turn.up.right.diamond.fill"
        case .quotes: return "quote.opening"
        }
    }
}

/// Элемент результата поиска командной палитры
public struct CommandPaletteItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let category: CommandPaletteCategory
    public let icon: String
    public let accentColor: Color
    public let actionTag: String
    public let execute: () -> Void

    public init(
        title: String,
        subtitle: String,
        category: CommandPaletteCategory,
        icon: String,
        accentColor: Color,
        actionTag: String = "",
        execute: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.icon = icon
        self.accentColor = accentColor
        self.actionTag = actionTag
        self.execute = execute
    }
}

/// Интеллектуальный поисковый движок командной палитры (Command Palette Engine)
public struct CommandPaletteEngine {

    /// Выполняет нечеткий и префиксный поиск по книгам, действиям и разделам
    public static func search(
        query: String,
        books: [Book],
        quotes: [Quote],
        onSelectBook: @escaping (Book) -> Void,
        onNavigateTab: @escaping (Int) -> Void,
        onTriggerAction: @escaping (String) -> Void
    ) -> [CommandPaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        var results: [CommandPaletteItem] = []

        // 1. Стандартные системные действия
        let systemActions: [CommandPaletteItem] = [
            CommandPaletteItem(
                title: "Начать сессию чтения",
                subtitle: "Запустить интеллектуальный таймер и трекер страниц",
                category: .actions,
                icon: "play.circle.fill",
                accentColor: .green,
                actionTag: "startTimer",
                execute: { onTriggerAction("startTimer") }
            ),
            CommandPaletteItem(
                title: "Ночные часы StandBy",
                subtitle: "Минималистичный прикроватный режим с OLED 1800K",
                category: .actions,
                icon: "bed.double.fill",
                accentColor: .orange,
                actionTag: "standBy",
                execute: { onTriggerAction("standBy") }
            ),
            CommandPaletteItem(
                title: "Включить звук камина / дождя",
                subtitle: "Акустический пространственный аудио-ландшафт",
                category: .actions,
                icon: "headphones",
                accentColor: .indigo,
                actionTag: "soundscape",
                execute: { onTriggerAction("soundscape") }
            ),
            CommandPaletteItem(
                title: "Мастерская экслибриса",
                subtitle: "Создать и настроить персональный книжный знак",
                category: .actions,
                icon: "seal.fill",
                accentColor: Color(red: 0.85, green: 0.68, blue: 0.28),
                actionTag: "exlibris",
                execute: { onTriggerAction("exlibris") }
            ),
            CommandPaletteItem(
                title: "Добавить новую книгу",
                subtitle: "Ручной ввод, сканер штрихкода ISBN или поиск Google Books",
                category: .actions,
                icon: "plus.circle.fill",
                accentColor: Color(red: 0.52, green: 0.14, blue: 0.20),
                actionTag: "addBook",
                execute: { onTriggerAction("addBook") }
            ),
            CommandPaletteItem(
                title: "Книжный Оракул",
                subtitle: "Случайный мудрый совет и книга под настроение",
                category: .actions,
                icon: "sparkles",
                accentColor: .purple,
                actionTag: "oracle",
                execute: { onTriggerAction("oracle") }
            ),
            CommandPaletteItem(
                title: "Синхронизация с Obsidian",
                subtitle: "Экспорт заметок в персональный Markdown Vault",
                category: .actions,
                icon: "arrow.triangle.2.circlepath",
                accentColor: .blue,
                actionTag: "obsidian",
                execute: { onTriggerAction("obsidian") }
            ),
            CommandPaletteItem(
                title: "Проверить обновления",
                subtitle: "Свежие релизы с GitHub Releases",
                category: .actions,
                icon: "arrow.clockwise.circle.fill",
                accentColor: .teal,
                actionTag: "update",
                execute: { onTriggerAction("update") }
            )
        ]

        // 2. Навигация по 5 главным разделам
        let navigationTabs: [CommandPaletteItem] = [
            CommandPaletteItem(title: "Дашборд чтения", subtitle: "Главная страница и текущий прогресс", category: .navigation, icon: "gauge", accentColor: .blue, actionTag: "tab:0", execute: { onNavigateTab(0) }),
            CommandPaletteItem(title: "Библиотека", subtitle: "Каталог книг, полки и книжные циклы", category: .navigation, icon: "books.vertical.fill", accentColor: .brown, actionTag: "tab:1", execute: { onNavigateTab(1) }),
            CommandPaletteItem(title: "Хроника (Литературный журнал)", subtitle: "Цитаты, OCR, заметки и матрица Бинго", category: .navigation, icon: "quote.bubble.fill", accentColor: Color(red: 0.52, green: 0.14, blue: 0.20), actionTag: "tab:2", execute: { onNavigateTab(2) }),
            CommandPaletteItem(title: "Аналитика и Пантеон", subtitle: "Статистика, графики и читательские трофеи", category: .navigation, icon: "chart.bar.xaxis", accentColor: .yellow, actionTag: "tab:3", execute: { onNavigateTab(3) }),
            CommandPaletteItem(title: "Кабинет Святилища", subtitle: "Представительский центр, настройки и хранилище", category: .navigation, icon: "lock.shield.fill", accentColor: .cyan, actionTag: "tab:4", execute: { onNavigateTab(4) })
        ]

        if trimmed.isEmpty {
            // Если запрос пустой, предлагаем быстрые действия и навигацию
            return systemActions + navigationTabs
        }

        // Фильтрация действий
        let matchingActions = systemActions.filter {
            $0.title.lowercased().contains(trimmed) || $0.subtitle.lowercased().contains(trimmed)
        }
        results.append(contentsOf: matchingActions)

        // Фильтрация навигации
        let matchingNav = navigationTabs.filter {
            $0.title.lowercased().contains(trimmed) || $0.subtitle.lowercased().contains(trimmed)
        }
        results.append(contentsOf: matchingNav)

        // Поиск по книгам
        let matchingBooks = books.filter { book in
            book.title.lowercased().contains(trimmed) ||
            book.author.lowercased().contains(trimmed) ||
            book.genre.rawValue.lowercased().contains(trimmed) ||
            (book.hasCycle && book.cycleName.lowercased().contains(trimmed))
        }

        for book in matchingBooks.prefix(12) {
            results.append(
                CommandPaletteItem(
                    title: book.title,
                    subtitle: "\(book.author) • \(book.genre.rawValue)",
                    category: .books,
                    icon: "book.closed.fill",
                    accentColor: book.genre.accentColor,
                    actionTag: "book:\(book.id.uuidString)",
                    execute: { onSelectBook(book) }
                )
            )
        }

        // Поиск по цитатам
        let matchingQuotes = quotes.filter { q in
            q.text.lowercased().contains(trimmed) || q.author.lowercased().contains(trimmed)
        }

        for quote in matchingQuotes.prefix(6) {
            results.append(
                CommandPaletteItem(
                    title: "«\(quote.text.prefix(60))...»",
                    subtitle: quote.author.isEmpty ? "Цитата из книги" : quote.author,
                    category: .quotes,
                    icon: "quote.opening",
                    accentColor: Color(red: 0.52, green: 0.14, blue: 0.20),
                    actionTag: "quote:\(quote.id.uuidString)",
                    execute: { onTriggerAction("quote:\(quote.id.uuidString)") }
                )
            )
        }

        return results
    }
}

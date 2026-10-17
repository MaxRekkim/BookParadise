---
name: e2e-testing
description: >-
  Автоматизирует сквозные пользовательские сценарии через UI-инструменты (XCTest UI, Playwright, Maestro).
---

# Сквозное UI-тестирование (E2E Testing)

Данный навык автоматизирует действия реального пользователя от запуска приложения до достижения цели.

## Паттерн Page Object / Screen Object
- Инкапсулировать поиск элементов и действия с экраном в отдельный класс:
```swift
class LibraryScreen {
    let app: XCUIApplication
    
    var addBookButton: XCUIElement { app.buttons["AddBookButton"] }
    
    func tapAddBook() -> AddBookSheetScreen {
        addBookButton.tap()
        return AddBookSheetScreen(app: app)
    }
}
```
- Использование `accessibilityIdentifier` для надежного поиска элементов без привязки к локализации текста.

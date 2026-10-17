---
name: unit-testing
description: >-
  Пишет изолированные модульные тесты для функций и классов с использованием моков, стабов и шаблона AAA (Arrange-Act-Assert).
---

# Модульное тестирование (Unit Testing)

Данный навык покрывает базовую логику надежными и быстрыми автоматическими тестами.

## Шаблон AAA (Arrange-Act-Assert)
```swift
func test_calculateStreak_withValidDailyReading_increasesStreak() {
    // 1. Arrange (Подготовка)
    let manager = StreakManager(storage: MockStorage())
    let today = Date()
    
    // 2. Act (Действие)
    manager.recordReading(date: today)
    
    // 3. Assert (Проверка)
    XCTAssertEqual(manager.currentStreak, 1)
}
```

## Принципы FIRST
- **Fast**: выполняются за миллисекунды.
- **Isolated**: не зависят от сети, диска или других тестов.
- **Repeatable**: выдают 100% одинаковый результат при каждом запуске.
- **Self-validating**: однозначный результат Pass/Fail без ручного разбора логов.
- **Timely**: пишутся вместе с кодом (или до него по TDD).

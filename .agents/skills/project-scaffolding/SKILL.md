---
name: project-scaffolding
description: >-
  Создает чистую структуру каталогов, базовые конфигурации сборки, линтеры, форматирование и переменные окружения.
---

# Генерация каркаса проекта (Project Scaffolding)

Данный навык инициализирует новые проекты и модули по промышленным стандартам разработки.

## Структура каталогов
```text
Project/
├── Sources/ (или lib/ / src/)
│   ├── Models/
│   ├── Services/
│   ├── ViewModels/ (или Controllers/)
│   ├── Views/ (или Components/)
│   └── Utils/
├── Tests/
│   ├── UnitTests/
│   └── IntegrationTests/
├── Resources/
│   └── Assets/
├── Config/
│   ├── .env.example
│   └── build_settings
└── README.md
```

## Базовый стек конфигураций
- **Контроль стиля**: `.swiftlint.yml`, `.eslintrc`, `analysis_options.yaml`.
- **Игнорирование мусора**: исчерпывающий `.gitignore` (бинарники, кэши, секреты, ключи).
- **Конфигурация окружений**: разделение `Development`, `Staging`, `Production`.

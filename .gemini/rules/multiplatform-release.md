# Multiplatform Release Rule (BookParadise)

## 🎯 Scope and Mandate
Каждый официальный релиз проекта **BookParadise** обязан выкатываться **одновременно и синхронно для всех четырёх поддерживаемых платформ**:
1. **iOS** (`.ipa`) — нативное SwiftUI-приложение для iPhone и iPad.
2. **macOS** (`.dmg`, `.pkg`) — нативное Mac Catalyst приложение для Mac (Apple Silicon & Intel).
3. **Android** (`.apk`) — мультиплатформенный клиент на Flutter (`BookParadise_Multiplatform`) для смартфонов и планшетов.
4. **Windows** (`.zip` с portable `.exe`) — настольный клиент на Flutter (`BookParadise_Multiplatform`) для Windows x64.

---

## 🏗 Архитектура репозитория

```text
BookParadise/
├── BookParadise/                   # Нативная кодовая база Apple (iOS & macOS)
│   ├── Sources/                    # SwiftUI Views, Models, Services, Widgets
│   └── BookParadise.xcodeproj      # Xcode-проект (версии MARKETING_VERSION и CURRENT_PROJECT_VERSION)
├── BookParadise_Multiplatform/     # Кроссплатформенная кодовая база (Android & Windows)
│   ├── lib/                        # Dart / Flutter (MVVM: models, services, views, widgets)
│   │   ├── data/                   # Book, Quote, Session, Enums, REST API, Cache, Themes
│   │   └── ui/                     # Adaptive navigation, Dashboard, Library, Passport, Quotes
│   ├── android/                    # Android shell & Gradle
│   └── pubspec.yaml                # Версия (синхронизируется с Xcode)
└── .github/workflows/ios-build.yml # Единый матричный CI/CD пайплайн сборки и релиза
```

---

## ⚙️ Правила версионирования и подготовки релиза

1. **Единая версия**:
   - При выпуске новой версии (например, `v2.3.1`) номер версии и билд должны быть строго согласованы:
     - `BookParadise.xcodeproj`: `MARKETING_VERSION = 2.3.1;`, `CURRENT_PROJECT_VERSION = 8;`
     - `BookParadise_Multiplatform/pubspec.yaml`: `version: 2.3.1+8`
     - `CHANGELOG.md`: подробное описание изменений под заголовком `[2.3.1] — YYYY-MM-DD`.

2. **Backend и Контракт Данных**:
   - Google Apps Script (`GoogleAppsScript/Code.gs`) является единым источником правды (`Single Source of Truth`).
   - Имена полей JSON, ключи оффлайн-кэша, 23 колонки таблицы (A–W) и структура листа Бинго (A–M) должны оставаться строго бинарно и семантически совместимыми между Swift и Dart реализациями.

3. **Синхронизация фич и UI-дизайна**:
   - В обоих клиентах сохраняется идентичная эстетика:
     - 4 авторские темы: `Уютная Библиотека` (Warm Amber), `Полночный Ридер` (Dark Slate), `Кофейный Винтаж` (Vintage Espresso), `Изумрудный Сад` (Forest Sage).
     - Thinking Orb с пульсирующей анимацией и частицами.
     - «Паспорт книги» без отображения служебных букв столбцов таблицы.
     - Дзен-секундомер сессии чтения с таймером и расчетом темпа.
     - Карточки цитат с высоким контрастом, никогда не выцветающие в темной теме.

---

## 🚀 Процесс публикации релиза

1. Все изменения коммитятся в ветку `main`.
2. Создается git-тег формата `vX.Y.Z` (например, `git tag v2.3.1 && git push origin v2.3.1`).
3. GitHub Actions автоматически запускает параллельную сборку:
   - `build-apple` (macOS runner) ➔ `BookParadise-2.3.1.ipa`, `BookParadise-2.3.1.dmg`, `BookParadise-2.3.1.pkg`
   - `build-android` (Ubuntu runner) ➔ `BookParadise-2.3.1-Android.apk`
   - `build-windows` (Windows runner) ➔ `BookParadise-2.3.1-Windows-x64.zip`
4. Финальная джоба `publish-release` скачивает все 5 артефактов и формирует единый релиз на GitHub.

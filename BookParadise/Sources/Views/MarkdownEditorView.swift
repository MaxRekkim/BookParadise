import SwiftUI

public enum EditorMode: String, CaseIterable, Identifiable {
    case edit = "Редактор"
    case preview = "Просмотр"
    case split = "Сплит"
    
    public var id: String { rawValue }
}

public enum EditorFont: String, CaseIterable, Identifiable {
    case serif = "Книжный Serif"
    case sans = "Современный Sans"
    case mono = "Код / Mono"
    
    public var id: String { rawValue }
    
    public var design: Font.Design {
        switch self {
        case .serif: return .serif
        case .sans: return .default
        case .mono: return .monospaced
        }
    }
}

public struct MarkdownEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var noteStore = ReadingNoteStore.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var note: ReadingNote
    @State private var mode: EditorMode = .edit
    @State private var selectedFont: EditorFont = .serif
    @State private var fontSize: CGFloat = 16.0
    @State private var showingSlashCommands: Bool = false
    @State private var newTagText: String = ""
    @State private var showingBookPicker: Bool = false
    @State private var showingExportSheet: Bool = false
    
    private let isNewNote: Bool
    
    public init(viewModel: LibraryViewModel, note: ReadingNote? = nil, initialBookId: Int? = nil) {
        self.viewModel = viewModel
        if let existing = note {
            self._note = State(initialValue: existing)
            self.isNewNote = false
        } else {
            let initialBook = viewModel.books.first(where: { $0.id == initialBookId })
            let fresh = ReadingNote(
                bookId: initialBook?.id,
                bookTitle: initialBook?.title,
                title: "",
                content: ""
            )
            self._note = State(initialValue: fresh)
            self.isNewNote = true
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Верхняя панель переключения режима и типографики
                topToolbar
                
                Divider()
                
                // Основная рабочая область в зависимости от режима
                GeometryReader { geo in
                    let isWide = geo.size.width > 700
                    
                    if mode == .edit {
                        editorSection
                    } else if mode == .preview {
                        previewSection
                    } else { // Split view
                        if isWide {
                            HStack(spacing: 0) {
                                editorSection
                                    .frame(width: geo.size.width / 2)
                                
                                Divider()
                                
                                previewSection
                                    .frame(width: geo.size.width / 2)
                            }
                        } else {
                            // На узком экране split переходит в редактор
                            editorSection
                        }
                    }
                }
                
                Divider()
                
                // Нижняя панель статистики и быстрых Markdown-тегов
                bottomActionBar
            }
            .navigationTitle(note.title.isEmpty ? "Новая заметка" : note.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveAndDismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingSlashCommands) {
                slashCommandSheet
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingBookPicker) {
                bookPickerSheet
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
        }
    }
    
    // MARK: - Верхняя панель настроек
    private var topToolbar: some View {
        HStack(spacing: 12) {
            // Переключатель Редактор / Просмотр / Сплит
            Picker("Режим", selection: $mode) {
                ForEach(EditorMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
            
            Spacer()
            
            // Выбор шрифта
            Menu {
                Picker("Шрифт", selection: $selectedFont) {
                    ForEach(EditorFont.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                
                Divider()
                
                Button(action: { fontSize = max(13, fontSize - 1) }) {
                    Label("Уменьшить размер", systemImage: "textformat.size.smaller")
                }
                Button(action: { fontSize = min(24, fontSize + 1) }) {
                    Label("Увеличить размер", systemImage: "textformat.size.larger")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "textformat")
                    Text("\(Int(fontSize)) pt")
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(8)
            }
            
            // Связка с книгой
            Button(action: { showingBookPicker = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "book.closed")
                    Text(note.bookTitle ?? "Привязать книгу")
                        .lineLimit(1)
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(note.bookId != nil ? theme.primaryAccent.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                .foregroundColor(note.bookId != nil ? theme.primaryAccent : .primary)
                .cornerRadius(8)
            }
            
            // Экспорт
            Button(action: { showingExportSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    // MARK: - Секция Редактора
    private var editorSection: some View {
        VStack(spacing: 8) {
            // Поле ввода заголовка
            TextField("Заголовок заметки или главы...", text: $note.title)
                .font(.system(size: 20, weight: .bold, design: selectedFont.design))
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            // Теги
            tagChipsView
                .padding(.horizontal, 16)
            
            // Многострочный текст редактора
            TextEditor(text: $note.content)
                .font(.system(size: fontSize, design: selectedFont.design))
                .lineSpacing(5)
                .padding(.horizontal, 12)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - Секция Просмотра Markdown
    private var previewSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Заголовок
                if !note.title.isEmpty {
                    Text(note.title)
                        .font(.system(size: 26, weight: .heavy, design: selectedFont.design))
                        .foregroundColor(Color(UIColor.label))
                }
                
                // Бейдж привязанной книги
                if let bookTitle = note.bookTitle {
                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .font(.caption2)
                        Text(bookTitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(theme.primaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.primaryAccent.opacity(0.12))
                    .cornerRadius(8)
                }
                
                // Отрендеренный Markdown контент
                if note.content.isEmpty {
                    Text("Здесь появится предпросмотр вашего текста...")
                        .font(.system(size: fontSize, design: selectedFont.design))
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 20)
                } else {
                    MarkdownRenderedView(markdown: note.content, fontDesign: selectedFont.design, baseFontSize: fontSize)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Теги заметки
    private var tagChipsView: some View {
        HStack(spacing: 6) {
            ForEach(note.tags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text("#\(tag)")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Button(action: { note.tags.removeAll { $0 == tag } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(12)
            }
            
            // Быстрое добавление тега
            TextField("+ тег", text: $newTagText)
                .font(.caption2)
                .frame(width: 60)
                .onSubmit {
                    let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !note.tags.contains(trimmed) {
                        note.tags.append(trimmed)
                        newTagText = ""
                    }
                }
            
            Spacer()
        }
    }
    
    // MARK: - Нижняя панель действий и Markdown-тулбар
    private var bottomActionBar: some View {
        HStack(spacing: 8) {
            // Кнопка вызова слэш-команд
            Button(action: { showingSlashCommands = true }) {
                HStack(spacing: 4) {
                    Text("/")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    Text("Команды")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.18))
                .foregroundColor(.orange)
                .cornerRadius(8)
            }
            
            // Быстрые кнопки форматирования
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    mdButton(label: "B", snippet: "**текст**")
                    mdButton(label: "I", snippet: "*текст*")
                    mdButton(label: "H1", snippet: "\n# Заголовок\n")
                    mdButton(label: "H2", snippet: "\n## Подзаголовок\n")
                    mdButton(label: "Цитата", snippet: "\n> \"Цитата\"\n")
                    mdButton(label: "Список", snippet: "\n- Пункт\n")
                    mdButton(label: "Чекбокс", snippet: "\n- [ ] Задача\n")
                    mdButton(label: "Инсайт", snippet: "\n💡 **Инсайт**: \n")
                    mdButton(label: "Спойлер", snippet: "\n> ⚠️ **Спойлер**: \n")
                    mdButton(label: "Разделитель", snippet: "\n---\n")
                }
            }
            
            Spacer()
            
            // Статистика слов и времени чтения
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(note.wordCount) слов")
                    .font(.system(size: 11, weight: .bold))
                Text("~\(note.readingTimeMinutes) мин чтения")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private func mdButton(label: String, snippet: String) -> some View {
        Button(action: {
            insertSnippet(snippet)
        }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    private func insertSnippet(_ snippet: String) {
        if note.content.isEmpty {
            note.content = snippet
        } else {
            note.content += (note.content.hasSuffix("\n") ? "" : "\n") + snippet
        }
    }
    
    private func saveAndDismiss() {
        if note.title.trimmingCharacters(in: .whitespaces).isEmpty {
            note.title = "Заметка от \(Date().formatted(date: .abbreviated, time: .shortened))"
        }
        noteStore.saveNote(note)
        dismiss()
    }
    
    // MARK: - Меню Слэш-команд
    private var slashCommandSheet: some View {
        NavigationStack {
            List {
                Section("Структура и заголовки") {
                    slashRow(title: "Заголовок 1 (#)", subtitle: "Крупный раздел статьи", snippet: "\n# Заголовок 1\n")
                    slashRow(title: "Заголовок 2 (##)", subtitle: "Подраздел или глава", snippet: "\n## Заголовок 2\n")
                    slashRow(title: "Заголовок 3 (###)", subtitle: "Малый подраздел", snippet: "\n### Заголовок 3\n")
                }
                
                Section("Выделения и цитаты") {
                    slashRow(title: "Цитата из книги (>)", subtitle: "Элегантный блок цитирования", snippet: "\n> \"Мудрая мысль из книги\"\n")
                    slashRow(title: "Инсайт читателя (💡)", subtitle: "Важная мысль или озарение", snippet: "\n💡 **Инсайт**: \n")
                    slashRow(title: "Предупреждение о спойлере (⚠️)", subtitle: "Скрыть сюжетный поворот", snippet: "\n> ⚠️ **Осторожно, спойлер**: \n")
                }
                
                Section("Списки и задачи") {
                    slashRow(title: "Маркированный список (-)", subtitle: "Простой перечень мыслей", snippet: "\n- Первый пункт\n- Второй пункт\n")
                    slashRow(title: "Чекбокс (- [ ])", subtitle: "Список дел или прочитанных глав", snippet: "\n- [ ] Прочитать главу\n- [x] Сделать конспект\n")
                    slashRow(title: "Разделительная черта (---)", subtitle: "Горизонтальная линия", snippet: "\n---\n")
                }
            }
            .navigationTitle("Команды Markdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        showingSlashCommands = false
                    }
                }
            }
        }
    }
    
    private func slashRow(title: String, subtitle: String, snippet: String) -> some View {
        Button(action: {
            insertSnippet(snippet)
            showingSlashCommands = false
        }) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.label))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Пикер привязки к книге
    private var bookPickerSheet: some View {
        NavigationStack {
            List {
                Button(action: {
                    note.bookId = nil
                    note.bookTitle = nil
                    showingBookPicker = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                        Text("Без привязки к книге (Общий дневник)")
                            .foregroundColor(.secondary)
                    }
                }
                
                ForEach(viewModel.books) { book in
                    Button(action: {
                        note.bookId = book.id
                        note.bookTitle = book.title
                        showingBookPicker = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(UIColor.label))
                                Text(book.author)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if note.bookId == book.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Связать с книгой")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { showingBookPicker = false }
                }
            }
        }
    }
    
    // MARK: - Меню экспорта
    private var exportSheet: some View {
        NavigationStack {
            List {
                Section("Экспорт документа") {
                    Button(action: {
                        UIPasteboard.general.string = note.content
                        showingExportSheet = false
                    }) {
                        Label("Скопировать Markdown в буфер", systemImage: "doc.on.doc")
                    }
                    
                    ShareLink(item: note.content, subject: Text(note.title), message: Text("Заметка из Книжного Рая: \(note.title)")) {
                        Label("Поделиться текстом заметки", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Экспорт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { showingExportSheet = false }
                }
            }
        }
    }
}

// MARK: - Компонент отображения Markdown с стилизацией цитат и блоков
public struct MarkdownRenderedView: View {
    public let markdown: String
    public let fontDesign: Font.Design
    public let baseFontSize: CGFloat
    
    public init(markdown: String, fontDesign: Font.Design, baseFontSize: CGFloat) {
        self.markdown = markdown
        self.fontDesign = fontDesign
        self.baseFontSize = baseFontSize
    }
    
    public var body: some View {
        let lines = markdown.components(separatedBy: .newlines)
        
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<lines.count, id: \.self) { i in
                let line = lines[i]
                renderLine(line)
            }
        }
    }
    
    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        if line.hasPrefix("# ") {
            Text(String(line.dropFirst(2)))
                .font(.system(size: baseFontSize + 8, weight: .heavy, design: fontDesign))
                .padding(.top, 6)
        } else if line.hasPrefix("## ") {
            Text(String(line.dropFirst(3)))
                .font(.system(size: baseFontSize + 4, weight: .bold, design: fontDesign))
                .padding(.top, 4)
        } else if line.hasPrefix("### ") {
            Text(String(line.dropFirst(4)))
                .font(.system(size: baseFontSize + 2, weight: .semibold, design: fontDesign))
                .padding(.top, 2)
        } else if line.hasPrefix("> ") {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.orange)
                    .frame(width: 4)
                
                Text(String(line.dropFirst(2)))
                    .font(.system(size: baseFontSize, weight: .medium, design: fontDesign))
                    .italic()
                    .foregroundColor(Color(UIColor.label).opacity(0.9))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.orange.opacity(0.06))
            .cornerRadius(6)
        } else if line.hasPrefix("- [ ] ") {
            HStack(spacing: 8) {
                Image(systemName: "square")
                    .foregroundColor(.secondary)
                Text(String(line.dropFirst(6)))
                    .font(.system(size: baseFontSize, design: fontDesign))
            }
        } else if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.square.fill")
                    .foregroundColor(.green)
                Text(String(line.dropFirst(6)))
                    .font(.system(size: baseFontSize, design: fontDesign))
                    .strikethrough()
                    .foregroundColor(.secondary)
            }
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: baseFontSize, weight: .bold))
                    .foregroundColor(.secondary)
                Text(String(line.dropFirst(2)))
                    .font(.system(size: baseFontSize, design: fontDesign))
            }
        } else if line.trimmingCharacters(in: .whitespaces) == "---" {
            Divider()
                .padding(.vertical, 8)
        } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
            Text(LocalizedStringKey(line))
                .font(.system(size: baseFontSize, design: fontDesign))
                .lineSpacing(4)
        }
    }
}

import SwiftUI
import UIKit

public struct QuoteCardShareView: View {
    public let quote: BookQuote
    public let book: Book
    public var onDismiss: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var selectedTheme: QuoteCardTheme = .parchment
    @State private var currentNote: String = ""
    @State private var showNoteOnCard: Bool = true
    @State private var isShowingNoteEditor: Bool = false
    @State private var noteDraftText: String = ""

    @State private var renderedCardImage: UIImage? = nil
    @State private var isCardCopied: Bool = false
    @State private var isTextCopied: Bool = false
    @State private var isPhotoSaved: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    public init(quote: BookQuote, book: Book, onDismiss: (() -> Void)? = nil) {
        self.quote = quote
        self.book = book
        self.onDismiss = onDismiss

        let initialNote = quote.note ?? ""
        _currentNote = State(initialValue: initialNote)
        _showNoteOnCard = State(initialValue: !initialNote.isEmpty)

        if let savedKey = UserDefaults.standard.string(forKey: "SelectedQuoteCardTheme"),
           let savedTheme = QuoteCardTheme(rawValue: savedKey) {
            _selectedTheme = State(initialValue: savedTheme)
        } else {
            _selectedTheme = State(initialValue: .parchment)
        }
    }

    private func closeSheet() {
        DispatchQueue.main.async {
            self.onDismiss?()
            self.dismiss()
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Сама открытка-цитата (которую можно сохранить как изображение)
                    quoteCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Блок персонализации (Выбор темы оформления и управление заметкой)
                    personalizationPanel
                        .padding(.horizontal, 16)

                    // Блок действий шеринга
                    VStack(spacing: 12) {
                        // 1. Быстрое копирование открытки (PNG) в буфер обмена
                        Button(action: copyCardImageToClipboard) {
                            HStack {
                                Image(systemName: isCardCopied ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
                                Text(isCardCopied ? "Открытка скопирована в буфер!" : "Скопировать открытку (PNG)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isCardCopied ? Color.green : theme.primaryAccent)
                            .cornerRadius(12)
                        }

                        // 2. Системный экспорт/поделиться
                        if let img = renderedCardImage {
                            ShareLink(
                                item: Image(uiImage: img),
                                preview: SharePreview("Цитата: «\(book.title)»", image: Image(uiImage: img))
                            ) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Поделиться изображением...")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primaryAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(theme.primaryAccent.opacity(0.12))
                                .cornerRadius(12)
                            }
                        }

                        // 3. Сохранить в Фотопленку (iOS)
                        Button(action: saveCardToPhotos) {
                            HStack {
                                Image(systemName: isPhotoSaved ? "checkmark" : "square.and.arrow.down")
                                Text(isPhotoSaved ? "Сохранено в Фото!" : "Сохранить фото в галерею")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }

                        // 4. Копировать текст цитаты
                        Button(action: copyQuoteText) {
                            HStack {
                                Image(systemName: isTextCopied ? "checkmark" : "doc.on.doc")
                                Text(isTextCopied ? "Текст скопирован в буфер!" : "Скопировать текст цитаты")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        }

                        // 5. Удалить цитату
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Удалить цитату")
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 30)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Цитата из книги")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        closeSheet()
                    }
                    .fontWeight(.semibold)
                    .keyboardShortcut(.defaultAction)
                    .keyboardShortcut(.cancelAction)
                }
            }
            .confirmationDialog("Удалить эту цитату?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    quotesManager.deleteQuote(id: quote.id)
                    closeSheet()
                }
                Button("Отмена", role: .cancel) {}
            }
            .sheet(isPresented: $isShowingNoteEditor) {
                NavigationStack {
                    Form {
                        Section(header: Text("Личная мысль / Заметка к цитате")) {
                            TextEditor(text: $noteDraftText)
                                .frame(minHeight: 120)
                        }
                    }
                    .navigationTitle(currentNote.isEmpty ? "Новая заметка" : "Редактировать заметку")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") { isShowingNoteEditor = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Сохранить") {
                                let trimmed = noteDraftText.trimmingCharacters(in: .whitespacesAndNewlines)
                                currentNote = trimmed
                                showNoteOnCard = !trimmed.isEmpty
                                quotesManager.updateQuote(id: quote.id, note: trimmed.isEmpty ? nil : trimmed, clearNote: trimmed.isEmpty)
                                isShowingNoteEditor = false
                                generateCardImage()
                            }
                        }
                    }
                }
                #if targetEnvironment(macCatalyst)
                .frame(minWidth: 420, minHeight: 320)
                #endif
            }
            .onAppear {
                generateCardImage()
            }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 500, idealWidth: 540, minHeight: 680, idealHeight: 760)
        #endif
    }

    // MARK: - Панель персонализации темы и заметки
    private var personalizationPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок блока
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(theme.primaryAccent)
                Text("Тема и оформление открытки")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }

            // Горизонтальный скролл с палитрами тем
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QuoteCardTheme.allCases) { cardTheme in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTheme = cardTheme
                                UserDefaults.standard.set(cardTheme.rawValue, forKey: "SelectedQuoteCardTheme")
                                generateCardImage()
                            }
                        }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(cardTheme.cardBackground)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)

                                    Circle()
                                        .stroke(cardTheme.accentColor, lineWidth: selectedTheme == cardTheme ? 3 : 1)
                                        .frame(width: 44, height: 44)

                                    Image(systemName: cardTheme.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(cardTheme.accentColor)
                                }

                                Text(cardTheme.title)
                                    .font(.caption2)
                                    .fontWeight(selectedTheme == cardTheme ? .bold : .medium)
                                    .foregroundColor(selectedTheme == cardTheme ? theme.primaryAccent : .secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }

            Divider()

            // Управление полем заметки
            VStack(spacing: 10) {
                HStack {
                    Toggle(isOn: $showNoteOnCard) {
                        HStack(spacing: 8) {
                            Image(systemName: "note.text")
                                .foregroundColor(theme.primaryAccent)
                            Text("Показывать заметку на открытке")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .tint(theme.primaryAccent)
                    .onChange(of: showNoteOnCard) { _ in
                        generateCardImage()
                    }
                }

                if showNoteOnCard {
                    if currentNote.isEmpty {
                        // Кнопка добавления заметки к цитате
                        Button(action: {
                            noteDraftText = ""
                            isShowingNoteEditor = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Добавить личную заметку к цитате")
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(theme.primaryAccent.opacity(0.1))
                            .cornerRadius(8)
                        }
                    } else {
                        // Заметка есть: просмотр, редактирование и удаление
                        HStack(alignment: .top, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Текст заметки:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("«\(currentNote)»")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .italic()
                                    .lineLimit(2)
                            }

                            Spacer()

                            Button(action: {
                                noteDraftText = currentNote
                                isShowingNoteEditor = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.caption)
                                    .foregroundColor(theme.primaryAccent)
                                    .padding(7)
                                    .background(theme.primaryAccent.opacity(0.12))
                                    .clipShape(Circle())
                            }

                            Button(action: {
                                withAnimation {
                                    currentNote = ""
                                    showNoteOnCard = false
                                    quotesManager.updateQuote(id: quote.id, clearNote: true)
                                    generateCardImage()
                                }
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(7)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Дизайн открытки цитаты
    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Верхняя плашка с кавычками и номером страницы
            HStack(alignment: .center) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(selectedTheme.accentColor)

                Spacer()

                if let page = quote.pageNumber, page > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                            .font(.caption2)
                        Text("Стр. \(page)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(selectedTheme.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(selectedTheme.accentColor.opacity(0.14))
                    .cornerRadius(8)
                }
            }

            // Основной текст цитаты в изысканном книжном шрифте
            Text("«\(quote.text)»")
                .font(.system(.title3, design: .serif))
                .fontWeight(.regular)
                .italic()
                .lineSpacing(6)
                .foregroundColor(selectedTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Заметка читателя (если включена и не пустая)
            if showNoteOnCard && !currentNote.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundColor(selectedTheme.accentColor)
                        Text("Заметка:")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(selectedTheme.accentColor)
                    }
                    Text(currentNote)
                        .font(.footnote)
                        .foregroundColor(selectedTheme.secondaryText)
                        .italic()
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(selectedTheme.noteBackground)
                .cornerRadius(8)
            }

            Divider()
                .overlay(selectedTheme.dividerColor)

            // Футер открытки: Автор, Название и брендинг «Книжный Рай»
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(book.author)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(selectedTheme.secondaryText)
                        .textCase(.uppercase)

                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.heavy)
                        .foregroundColor(selectedTheme.primaryText)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundColor(selectedTheme.accentColor)
                    Text("Книжный Рай")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTheme.accentColor)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(selectedTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(selectedTheme.borderColor, lineWidth: 1)
        )
        .environment(\.colorScheme, selectedTheme.isDark ? .dark : .light)
    }

    // MARK: - Действия
    @MainActor
    private func renderCard() -> UIImage? {
        let renderer = ImageRenderer(content: quoteCard.frame(width: 360))
        #if targetEnvironment(macCatalyst)
        renderer.scale = 2.0
        #else
        renderer.scale = UIScreen.main.scale
        #endif
        return renderer.uiImage
    }

    @MainActor
    private func generateCardImage() {
        if let img = renderCard() {
            self.renderedCardImage = img
        }
    }

    @MainActor
    private func copyCardImageToClipboard() {
        let img = renderedCardImage ?? renderCard()
        if let img = img {
            UIPasteboard.general.image = img
            isCardCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isCardCopied = false
            }
        }
    }

    @MainActor
    private func saveCardToPhotos() {
        let img = renderedCardImage ?? renderCard()
        guard let img = img else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        isPhotoSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isPhotoSaved = false
        }
    }

    private func copyQuoteText() {
        var formatted = "«\(quote.text)»\n\n— \(book.author), «\(book.title)»"
        if let page = quote.pageNumber, page > 0 {
            formatted += " (стр. \(page))"
        }
        if showNoteOnCard && !currentNote.isEmpty {
            formatted += "\nЗаметка: \(currentNote)"
        }
        UIPasteboard.general.string = formatted
        isTextCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isTextCopied = false
        }
    }
}

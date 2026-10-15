import SwiftUI
import UIKit

public struct QuoteCardShareView: View {
    public let quote: BookQuote
    public let book: Book
    public var onDismiss: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var renderedCardImage: UIImage? = nil
    @State private var isCardCopied: Bool = false
    @State private var isTextCopied: Bool = false
    @State private var isPhotoSaved: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    public init(quote: BookQuote, book: Book, onDismiss: (() -> Void)? = nil) {
        self.quote = quote
        self.book = book
        self.onDismiss = onDismiss
    }

    private func closeSheet() {
        onDismiss?()
        dismiss()
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Сама открытка-цитата (которую можно сохранить как изображение)
                    quoteCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Блок действий шеринга
                    VStack(spacing: 12) {
                        // 1. Быстрое копирование открытки (PNG) в буфер обмена (идеально для Mac, Telegram, Заметок)
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

                        // 2. Системный экспорт/поделиться (нативный ShareLink SwiftUI без блокирующих модальных окон)
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
                                Text(isTextCopied ? "Текст скопирован в буфер!" : "Скопировать только текст цитаты")
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
                            .padding(.top, 6)
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { closeSheet() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { closeSheet() }
                }
            }
            .confirmationDialog("Удалить эту цитату?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    quotesManager.deleteQuote(id: quote.id)
                    closeSheet()
                }
                Button("Отмена", role: .cancel) {}
            }
            .onAppear {
                generateCardImage()
            }
        }
        #if targetEnvironment(macCatalyst)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 620, idealHeight: 720)
        #endif
    }

    // MARK: - Дизайн открытки цитаты
    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Верхняя плашка с кавычками и номером страницы
            HStack(alignment: .center) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(theme.primaryAccent)

                Spacer()

                if let page = quote.pageNumber, page > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                            .font(.caption2)
                        Text("Стр. \(page)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(theme.primaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.primaryAccent.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            // Основной текст цитаты в изысканном книжном шрифте
            Text("«\(quote.text)»")
                .font(.system(.title3, design: .serif))
                .fontWeight(.regular)
                .italic()
                .lineSpacing(6)
                .foregroundColor(Color(UIColor.label))
                .frame(maxWidth: .infinity, alignment: .leading)

            // Заметка читателя (если есть)
            if let note = quote.note, !note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil.line")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryAccent)
                        Text("Заметка:")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(theme.secondaryAccent)
                    }
                    Text(note)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(8)
            }

            Divider()

            // Футер открытки: Автор, Название и брендинг «Книжный Рай»
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(book.author)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(book.title)
                        .font(.subheadline)
                        .fontWeight(.heavy)
                        .foregroundColor(Color(UIColor.label))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundColor(theme.primaryAccent)
                    Text("Книжный Рай")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.paperBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.primaryAccent.opacity(0.2), lineWidth: 1)
        )
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
        if let note = quote.note, !note.isEmpty {
            formatted += "\nЗаметка: \(note)"
        }
        UIPasteboard.general.string = formatted
        isTextCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isTextCopied = false
        }
    }
}

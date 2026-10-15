import SwiftUI
import UIKit

public struct QuoteCardShareView: View {
    public let quote: BookQuote
    public let book: Book
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var renderedImage: UIImage? = nil
    @State private var isSharingImage: Bool = false
    @State private var isCopied: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    public init(quote: BookQuote, book: Book) {
        self.quote = quote
        self.book = book
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Сама открытка-цитата (которую можно сохранить как изображение)
                    quoteCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Кнопки действий
                    VStack(spacing: 12) {
                        Button(action: shareCardAsImage) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                Text("Поделиться карточкой (Фото)")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.primaryAccent)
                            .cornerRadius(12)
                        }

                        Button(action: copyQuoteText) {
                            HStack {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "Скопировано в буфер!" : "Скопировать текст цитаты")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primaryAccent.opacity(0.12))
                            .cornerRadius(12)
                        }

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
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .sheet(isPresented: $isSharingImage) {
                if let image = renderedImage {
                    ActivityView(activityItems: [image])
                }
            }
            .confirmationDialog("Удалить эту цитату?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    quotesManager.deleteQuote(id: quote.id)
                    dismiss()
                }
                Button("Отмена", role: .cancel) {}
            }
        }
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
    private func shareCardAsImage() {
        let renderer = ImageRenderer(content: quoteCard.frame(width: 360))
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            self.renderedImage = image
            self.isSharingImage = true
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
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCopied = false
        }
    }
}

// UIActivityViewController Wrapper
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

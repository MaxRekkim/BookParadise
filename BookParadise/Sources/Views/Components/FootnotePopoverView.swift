import SwiftUI

/// Модель сноски или комментария автора
public struct BookFootnote: Identifiable, Codable, Equatable {
    public let id: String
    public let index: Int
    public let term: String
    public let explanation: String
    public let chapterTitle: String?

    public init(id: String = UUID().uuidString, index: Int, term: String, explanation: String, chapterTitle: String? = nil) {
        self.id = id
        self.index = index
        self.term = term
        self.explanation = explanation
        self.chapterTitle = chapterTitle
    }
}

/// Всплывающее окно авторской сноски/примечания (Popover Footnotes)
/// Позволяет мгновенно изучить значение термина или комментарий автора без потери позиции чтения
public struct FootnotePopoverView: View {
    public let footnote: BookFootnote
    public var onDismiss: (() -> Void)? = nil

    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    public init(footnote: BookFootnote, onDismiss: (() -> Void)? = nil) {
        self.footnote = footnote
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Верхняя плашка: номер сноски и закрытие
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.primaryAccent)

                    Text("СНОСКА [\(footnote.index)]")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.primaryAccent.opacity(0.12))
                .cornerRadius(6)

                Spacer()

                Button(action: {
                    if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }

            // Поясняемый термин или цитата
            Text(AuthorTypographerEngine.formatTitle(footnote.term))
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            Divider()

            // Текст толкования / комментария
            Text(AuthorTypographerEngine.formatTitle(footnote.explanation))
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let chapter = footnote.chapterTitle {
                HStack {
                    Spacer()
                    Text(chapter)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                        .italic()
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
        .padding(20)
    }
}

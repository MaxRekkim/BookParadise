import SwiftUI
import UIKit

/// Темы оформления эстетичной карточки книги в стандартах Apple Human Interface Guidelines
public enum BookShareCardTheme: String, CaseIterable, Identifiable {
    case midnightSlate = "midnight_slate"
    case royalWine = "royal_wine"
    case emeraldElegance = "emerald_elegance"
    case vintageParchment = "vintage_parchment"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .midnightSlate: return "Полуночный сланец"
        case .royalWine: return "Королевский Бордо"
        case .emeraldElegance: return "Изумрудный атлас"
        case .vintageParchment: return "Пергамент"
        }
    }

    public var gradient: LinearGradient {
        switch self {
        case .midnightSlate:
            return LinearGradient(
                colors: [Color(red: 0.08, green: 0.10, blue: 0.14), Color(red: 0.04, green: 0.05, blue: 0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .royalWine:
            return LinearGradient(
                colors: [Color(red: 0.32, green: 0.08, blue: 0.14), Color(red: 0.10, green: 0.03, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .emeraldElegance:
            return LinearGradient(
                colors: [Color(red: 0.06, green: 0.18, blue: 0.12), Color(red: 0.02, green: 0.08, blue: 0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .vintageParchment:
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.92, blue: 0.85), Color(red: 0.88, green: 0.84, blue: 0.74)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public var accentColor: Color {
        switch self {
        case .midnightSlate: return Color(red: 0.85, green: 0.88, blue: 0.92)
        case .royalWine: return Color(red: 0.85, green: 0.25, blue: 0.35)
        case .emeraldElegance: return Color(red: 0.35, green: 0.75, blue: 0.50)
        case .vintageParchment: return Color(red: 0.55, green: 0.35, blue: 0.15)
        }
    }

    public var textColor: Color {
        switch self {
        case .vintageParchment: return Color(red: 0.15, green: 0.12, blue: 0.10)
        default: return .white
        }
    }

    public var subtitleColor: Color {
        switch self {
        case .vintageParchment: return Color(red: 0.40, green: 0.35, blue: 0.30)
        default: return Color.white.opacity(0.7)
        }
    }
}

/// Модальное окно генерации и шеринга эстетичной карточки книги
public struct BookShareCardView: View {
    public let book: Book
    public var customQuote: String? = nil
    public var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared

    @State private var selectedTheme: BookShareCardTheme = .midnightSlate
    @State private var renderedCardImage: UIImage? = nil
    @State private var isCopied: Bool = false
    @State private var isSavedToPhotos: Bool = false

    public init(book: Book, customQuote: String? = nil, onDismiss: (() -> Void)? = nil) {
        self.book = book
        self.customQuote = customQuote
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Интерактивное превью карточки
                    shareCard
                        .padding(.top, 10)

                    // 2. Выбор визуального стиля
                    themeSelector
                        .padding(.horizontal)

                    // 3. Кнопки действий
                    actionButtons
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Карточка книги")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                generateCardImage()
            }
        }
    }

    // MARK: - Дизайн карточки книги
    private var shareCard: some View {
        VStack(spacing: 16) {
            // Верхняя плашка
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundColor(selectedTheme.accentColor)
                    Text("КНИЖНЫЙ РАЙ • ИТОГИ")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(selectedTheme.subtitleColor)
                }

                Spacer()

                Text("2026")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(selectedTheme.subtitleColor)
            }

            // Обложка с 3D-тенью
            BookCoverView(
                coverURL: book.cleanCoverURL,
                title: book.title,
                author: book.author,
                genre: book.genre,
                cornerRadius: 14
            )
            .frame(width: 170, height: 250)
            .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 10)
            .padding(.vertical, 6)

            // Название книги и автор
            VStack(spacing: 4) {
                Text(book.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(book.author)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selectedTheme.subtitleColor)
            }

            // Звезды рейтинга
            if let rating = book.rating, rating.numericScore > 0 {
                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating.numericScore ? "star.fill" : "star")
                            .font(.system(size: 13))
                            .foregroundColor(star <= rating.numericScore ? Color.yellow : Color.gray.opacity(0.4))
                    }
                    if rating == .masterpiece {
                        Text("Шедевр!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.leading, 4)
                    }
                }
            }

            // Индикатор читательского темпоритма
            soundwaveVisualizer

            // Статистические плашки (Bento)
            HStack(spacing: 8) {
                statPill(
                    title: "СТРАНИЦЫ",
                    value: "\(book.pagesRead) / \(book.totalPages)",
                    icon: "book.pages.fill"
                )

                statPill(
                    title: "ПРОГРЕСС",
                    value: "\(Int(book.progressPercent))%",
                    icon: "chart.line.uptrend.xyaxis"
                )

                statPill(
                    title: "СТАТУС",
                    value: book.status.rawValue,
                    icon: book.status.iconName
                )
            }

            // Цитата (если передана)
            if let q = customQuote, !q.isEmpty {
                VStack(spacing: 4) {
                    Text("«\(q)»")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(selectedTheme.textColor.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 10)
                }
                .padding(.top, 4)
            }

            Divider()
                .background(selectedTheme.subtitleColor.opacity(0.2))

            // Нижний литературный штамп и эмблема издания
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 11))
                        .foregroundColor(selectedTheme.accentColor)
                    Text("КНИЖНЫЙ РАЙ")
                        .font(.system(size: 11, weight: .bold, design: .serif))
                        .tracking(1.2)
                        .foregroundColor(selectedTheme.textColor)
                }

                Spacer()

                Text("Литературное издание")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(selectedTheme.subtitleColor)
            }
            .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(selectedTheme.gradient)
                .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(selectedTheme.accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var soundwaveVisualizer: some View {
        HStack(spacing: 3) {
            ForEach(0..<24, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(selectedTheme.accentColor.opacity(i % 3 == 0 ? 0.9 : 0.5))
                    .frame(width: 3, height: [6, 12, 18, 10, 24, 16, 8, 20, 14, 22, 12, 16, 20, 10, 24, 14, 18, 8, 12, 22, 16, 10, 18, 8][i % 24])
            }
        }
        .frame(height: 26)
        .padding(.vertical, 2)
    }

    private func statPill(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(selectedTheme.accentColor)
                Text(title)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(selectedTheme.subtitleColor)
            }
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.18))
        .cornerRadius(10)
    }

    // MARK: - Переключатель тем
    private var themeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Стиль карточки")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BookShareCardTheme.allCases) { item in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTheme = item
                                generateCardImage()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.accentColor)
                                    .frame(width: 10, height: 10)
                                Text(item.title)
                                    .font(.caption)
                                    .fontWeight(selectedTheme == item ? .bold : .medium)
                                    .foregroundColor(selectedTheme == item ? .white : Color(UIColor.label))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTheme == item ? theme.primaryAccent : Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Кнопки действий
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 1. Скопировать изображение в буфер обмена
            Button(action: copyImageToClipboard) {
                HStack {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.clipboard.fill")
                    Text(isCopied ? "Скопировано в буфер обмена!" : "Скопировать карточку (PNG)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isCopied ? Color.green : theme.primaryAccent)
                .cornerRadius(14)
                .shadow(color: (isCopied ? Color.green : theme.primaryAccent).opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(.plain)

            // 2. Системный экспорт через ShareLink
            if let img = renderedCardImage {
                ShareLink(
                    item: Image(uiImage: img),
                    preview: SharePreview("Итоги: «\(book.title)»", image: Image(uiImage: img))
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Поделиться изображением")
                    }
                    .font(.headline)
                    .foregroundColor(theme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }

            // 3. Сохранить в Фотоплёнку
            Button(action: saveToPhotos) {
                HStack {
                    Image(systemName: isSavedToPhotos ? "photo.fill.on.rectangle.fill" : "square.and.arrow.down")
                    Text(isSavedToPhotos ? "Сохранено в Фото!" : "Сохранить в Фотоплёнку")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    // MARK: - Рендеринг и утилиты
    private func generateCardImage() {
        Task { @MainActor in
            let renderer = ImageRenderer(content: shareCard.frame(width: 360))
            renderer.scale = UIScreen.main.scale
            if let image = renderer.uiImage {
                self.renderedCardImage = image
            }
        }
    }

    private func copyImageToClipboard() {
        guard let img = renderedCardImage else {
            generateCardImage()
            return
        }
        UIPasteboard.general.image = img
        HapticManager.shared.lightTap()
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isCopied = false
            }
        }
    }

    private func saveToPhotos() {
        guard let img = renderedCardImage else {
            generateCardImage()
            return
        }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        HapticManager.shared.lightTap()
        withAnimation {
            isSavedToPhotos = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isSavedToPhotos = false
            }
        }
    }
}

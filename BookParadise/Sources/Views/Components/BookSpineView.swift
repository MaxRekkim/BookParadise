import SwiftUI

public struct BookSpineView: View {
    public let book: Book
    @ObservedObject private var theme = ThemeManager.shared

    public init(book: Book) {
        self.book = book
    }

    private var spineWidth: CGFloat {
        let pages = book.totalPages
        // 200 стр -> ~30 pt, 500 стр -> ~42 pt, 900+ стр -> ~52 pt
        let calculated = 24.0 + (Double(pages) * 0.035)
        return CGFloat(max(28.0, min(54.0, calculated)))
    }

    private var spineHeight: CGFloat {
        // Натуральная вариация высоты книг на полке от 155 до 175 pt
        let seed = abs(book.id.hashValue) % 5
        return CGFloat(155 + seed * 4)
    }

    private var isTopRated: Bool {
        book.rating == .star5 || book.rating == .masterpiece
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Шелковая закладка-ляссе для читаемых книг (свисает снизу на полку)
            if book.status == .inProgress {
                Rectangle()
                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom))
                    .frame(width: 5, height: 16)
                    .offset(y: 12)
                    .shadow(radius: 1)
            }

            // Сам корешок книги
            ZStack {
                // 1. Объемный цилиндрический градиент корешка
                RoundedRectangle(cornerRadius: 3)
                    .fill(book.genre.accentColor)

                // Теневой 3D-градиент для выпуклости переплета
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.35), location: 0.0),
                                .init(color: .white.opacity(0.22), location: 0.25),
                                .init(color: .clear, location: 0.5),
                                .init(color: .black.opacity(0.35), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // 2. Декоративные ребра (бинты) сверху и снизу
                VStack {
                    decorativeRibs
                    Spacer()
                    if isTopRated {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.yellow)
                            .shadow(color: .black.opacity(0.5), radius: 1)
                    }
                    Spacer()
                    decorativeRibs
                }
                .padding(.vertical, 8)

                // 3. Вертикальное тиснение: Название и Автор
                VStack(spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
                        .fixedSize()
                        .rotationEffect(.degrees(-90))
                        .frame(maxHeight: spineHeight - 65)

                    if spineWidth >= 36 {
                        Text(book.author)
                            .font(.system(size: 8, weight: .medium, design: .serif))
                            .foregroundColor(.white.opacity(0.88))
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.7), radius: 1, y: 1)
                            .fixedSize()
                            .rotationEffect(.degrees(-90))
                            .frame(maxHeight: 45)
                    }
                }

                // 4. Индикатор завершенной книги
                if book.status == .read {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: spineWidth, height: spineHeight)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.35), radius: 2, x: 2, y: 1)
        }
    }

    private var decorativeRibs: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(height: 1)
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .frame(height: 1)
        }
        .padding(.horizontal, 2)
    }
}

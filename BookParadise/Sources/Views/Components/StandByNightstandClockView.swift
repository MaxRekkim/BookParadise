import SwiftUI

/// Прикроватный ночной режим ожидания (iOS StandBy Mode Desk Clock).
/// Активируется при горизонтальном расположении устройства на зарядке MagSafe:
/// - Истинный черный фон OLED (0 nits) с теплым свечением (Amber 1800K)
/// - Крупные благородные типографические часы
/// - Текущая читаемая книга с обложкой и кольцом суточного прогресса
/// - Литературная цитата дня для вечернего вдохновения
public struct StandByNightstandClockView: View {
    public let currentBook: Book?
    public var quoteOfTheDay: String = "Человек с хорошей книгой в руках никогда не может быть одиноким."
    public var quoteAuthor: String = "Карло Гольдони"
    public var onDismiss: (() -> Void)? = nil

    @State private var currentTime: Date = Date()
    @State private var ambientBreathing: Double = 0.85
    @Environment(\.dismiss) private var dismiss

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(
        currentBook: Book?,
        quoteOfTheDay: String = "Человек с хорошей книгой в руках никогда не может быть одиноким.",
        quoteAuthor: String = "Карло Гольдони",
        onDismiss: (() -> Void)? = nil
    ) {
        self.currentBook = currentBook
        self.quoteOfTheDay = quoteOfTheDay
        self.quoteAuthor = quoteAuthor
        self.onDismiss = onDismiss
    }

    private var amberGlow: Color {
        Color(red: 0.96, green: 0.65, blue: 0.28)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: currentTime)
    }

    private var secondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: currentTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: currentTime).capitalized
    }

    public var body: some View {
        ZStack {
            // Истинный черный OLED фон (0 нит)
            Color.black.ignoresSafeArea()

            // Мягкое фоновое эмбиент-свечение
            RadialGradient(
                colors: [amberGlow.opacity(0.12 * ambientBreathing), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            HStack(spacing: 40) {
                // Левая колонка: Текущая книга и прогресс
                leftBookSection

                // Тонкий вертикальный янтарный разделитель
                Rectangle()
                    .fill(amberGlow.opacity(0.2))
                    .frame(width: 1, height: 220)

                // Правая колонка: Крупные часы и цитата дня
                rightClockSection
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 32)

            // Кнопка выхода (невесомая в верхнем углу)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(amberGlow.opacity(0.5))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                ambientBreathing = 1.05
            }
        }
    }

    private var leftBookSection: some View {
        VStack(spacing: 16) {
            if let book = currentBook {
                HStack(spacing: 18) {
                    // Обложка книги
                    BookCoverView(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        genre: book.genre,
                        cornerRadius: 8
                    )
                    .frame(width: 90, height: 135)
                    .shadow(color: amberGlow.opacity(0.35), radius: 10, x: 0, y: 4)

                    // Детали книги
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ЧИТАЕТСЯ СЕЙЧАС")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(amberGlow.opacity(0.75))
                            .tracking(1.5)

                        Text(book.typographicTitle)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(book.typographicAuthor)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(1)

                        Spacer().frame(height: 4)

                        // Кольцо или полоса прогресса
                        HStack(spacing: 8) {
                            Text("\(book.pagesRead)/\(book.totalPages) стр.")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(amberGlow)

                            Text("•")
                                .foregroundColor(.white.opacity(0.3))

                            Text("\(Int(book.progressPercent))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // Тонкий янтарный прогресс-бар
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(amberGlow)
                                    .frame(width: max(4, geo.size.width * CGFloat(min(1.0, book.progressPercent / 100.0))))
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: 180)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(amberGlow.opacity(0.5))
                    Text("Выберите книгу для чтения")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rightClockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Время и секунды
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(timeString)
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundColor(amberGlow)
                    .shadow(color: amberGlow.opacity(0.5), radius: 8)

                Text(secondsString)
                    .font(.system(size: 20, weight: .light, design: .monospaced))
                    .foregroundColor(amberGlow.opacity(0.6))
            }

            // Дата
            Text(dateString)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .tracking(0.8)

            Spacer().frame(height: 4)

            // Цитата дня
            VStack(alignment: .leading, spacing: 4) {
                Text("«\(AuthorTypographerEngine.formatTitle(quoteOfTheDay))»")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.88))
                    .italic()
                    .lineLimit(3)

                Text("— \(AuthorTypographerEngine.formatAuthor(quoteAuthor))")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(amberGlow.opacity(0.85))
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

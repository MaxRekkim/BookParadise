import SwiftUI

/// Прикроватный ночной режим ожидания (iOS StandBy Mode Desk Clock).
/// Поддерживает адаптивное отображение:
/// - Портретный режим (вертикальный bedside-компаньон для чтения и сна)
/// - Горизонтальный режим (классический прикроватный MagSafe StandBy на док-станции)
/// - Истинный OLED Zero-Black (0 нит) фон для защиты глаз и мелатонина
/// - Выбор благородного ночного спектра (Янтарь 1800K, Глубокий Рубин 650nm, Теплая Свеча 2200K)
/// - Безупречная микротипографика без переносов букв и разрывов времени
/// - Быстрое управление звуковым пейзажем библиотеки (камин, дождь)
@MainActor
public struct StandByNightstandClockView: View {
    public let currentBook: Book?
    public var quoteOfTheDay: String = "Человек с хорошей книгой в руках никогда не может быть одиноким."
    public var quoteAuthor: String = "Карло Гольдони"
    public var onDismiss: (() -> Void)? = nil

    @ObservedObject private var soundscape = SoundscapeManager.shared

    /// Цветовой спектр ночного освещения
    public enum NightIllumination: String, CaseIterable, Identifiable {
        case amber = "Янтарь 1800K"
        case ruby = "Рубин 650nm"
        case candle = "Свеча 2200K"

        public var id: String { rawValue }

        public var color: Color {
            switch self {
            case .amber:
                return Color(red: 0.96, green: 0.65, blue: 0.28) // #F5A647
            case .ruby:
                return Color(red: 0.92, green: 0.25, blue: 0.28) // #EB4047
            case .candle:
                return Color(red: 0.98, green: 0.82, blue: 0.44) // #FAD270
            }
        }
    }

    @State private var currentTime: Date = Date()
    @State private var ambientBreathing: Double = 0.85
    @State private var selectedTheme: NightIllumination = .amber
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

    private var activeGlow: Color {
        selectedTheme.color
    }

    private var is12HourFormat: Bool {
        let format = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current) ?? ""
        return format.contains("a")
    }

    /// Только часы и минуты (например "12:31" или "00:31")
    private var timeOnlyString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = is12HourFormat ? "h:mm" : "HH:mm"
        return formatter.string(from: currentTime)
    }

    /// Префикс AM/PM если включен 12-часовой формат
    private var periodString: String? {
        guard is12HourFormat else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "a"
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
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                // Истинный черный OLED фон (0 нит)
                Color.black.ignoresSafeArea()

                // Мягкое фоновое эмбиент-свечение
                RadialGradient(
                    colors: [activeGlow.opacity(0.12 * ambientBreathing), Color.clear],
                    center: .center,
                    startRadius: 40,
                    endRadius: min(geometry.size.width, geometry.size.height) * 0.8
                )
                .ignoresSafeArea()

                // Контент в зависимости от ориентации
                if isLandscape {
                    landscapeContent(size: geometry.size)
                } else {
                    portraitContent(size: geometry.size)
                }

                // Верхняя панель управления (Soundscape, темы, закрытие)
                topControlBar(isLandscape: isLandscape)
            }
        }
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 90 {
                    closeView()
                }
            }
        )
        .onReceive(timer) { input in
            currentTime = input
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                ambientBreathing = 1.08
            }
        }
    }

    // MARK: - Верхняя панель управления
    private func topControlBar(isLandscape: Bool) -> some View {
        VStack {
            HStack(spacing: 16) {
                // Быстрый переключатель звукового фона
                Button(action: {
                    soundscape.togglePlayback()
                    HapticManager.shared.lightTap()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: soundscape.isPlaying ? "waveform" : "headphones")
                            .font(.system(size: 14, weight: .semibold))
                        if !isLandscape {
                            Text(soundscape.isPlaying ? "Звуки ночи" : "Тишина")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(activeGlow.opacity(soundscape.isPlaying ? 0.95 : 0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().stroke(activeGlow.opacity(0.2), lineWidth: 1))
                    )
                }

                Spacer()

                // Выбор ночного спектра (Янтарь, Рубин, Свеча)
                HStack(spacing: 8) {
                    ForEach(NightIllumination.allCases) { theme in
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTheme = theme
                            }
                            HapticManager.shared.selectionChanged()
                        }) {
                            Circle()
                                .fill(theme.color)
                                .frame(width: selectedTheme == theme ? 14 : 10, height: selectedTheme == theme ? 14 : 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedTheme == theme ? 1.5 : 0)
                                )
                                .shadow(color: theme.color.opacity(selectedTheme == theme ? 0.6 : 0), radius: 4)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                )

                // Кнопка выхода
                Button(action: {
                    closeView()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(activeGlow.opacity(0.6))
                }
            }
            .padding(.horizontal, isLandscape ? 36 : 24)
            .padding(.top, isLandscape ? 16 : 20)

            Spacer()
        }
    }

    // MARK: - ПОРТРЕТНЫЙ РЕЖИМ (iPhone вертикально)
    private func portraitContent(size: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 64)

            // 1. Крупные ночные часы
            VStack(spacing: 6) {
                clockDisplay(fontSize: 72)

                Text(dateString)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .tracking(0.5)
            }
            .padding(.top, 12)

            Spacer(minLength: 20)

            // 2. Карточка текущей читаемой книги
            if let book = currentBook {
                HStack(spacing: 16) {
                    // Обложка
                    BookCoverView(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        genre: book.genre,
                        cornerRadius: 8
                    )
                    .frame(width: 82, height: 124)
                    .shadow(color: activeGlow.opacity(0.35), radius: 12, x: 0, y: 4)

                    // Описание и прогресс
                    VStack(alignment: .leading, spacing: 6) {
                        Text("СЕЙЧАС В ЧТЕНИИ")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(activeGlow.opacity(0.85))
                            .tracking(2)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Text(book.typographicTitle)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(book.typographicAuthor)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundColor(Color.white.opacity(0.72))
                            .lineLimit(1)

                        Spacer().frame(height: 2)

                        // Прогресс чтения
                        HStack(spacing: 6) {
                            Text("\(book.pagesRead)/\(book.totalPages) стр.")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(activeGlow)
                                .lineLimit(1)

                            Text("•")
                                .foregroundColor(.white.opacity(0.3))

                            Text("\(Int(book.progressPercent))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // Индикатор прогресса
                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(activeGlow)
                                    .frame(width: max(4, barGeo.size.width * CGFloat(min(1.0, book.progressPercent / 100.0))))
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(activeGlow.opacity(0.18), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 36))
                        .foregroundColor(activeGlow.opacity(0.5))
                    Text("Выберите книгу для чтения перед сном")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(24)
            }

            Spacer(minLength: 20)

            // 3. Литературная цитата вечера
            VStack(spacing: 6) {
                Text("«\(AuthorTypographerEngine.formatTitle(quoteOfTheDay))»")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundColor(.white.opacity(0.88))
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 12)

                Text("— \(AuthorTypographerEngine.formatAuthor(quoteAuthor))")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(activeGlow.opacity(0.9))
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            // 4. Подсказка о повороте устройства
            HStack(spacing: 6) {
                Image(systemName: "rotate.right")
                    .font(.system(size: 11))
                Text("Поверните iPhone для горизонтального StandBy")
                    .font(.system(size: 10, weight: .regular))
            }
            .foregroundColor(.white.opacity(0.32))
            .padding(.bottom, 20)
        }
    }

    // MARK: - ГОРИЗОНТАЛЬНЫЙ РЕЖИМ (StandBy на док-станции MagSafe)
    private func landscapeContent(size: CGSize) -> some View {
        HStack(spacing: 36) {
            // Левая секция: Книга и прогресс
            HStack(spacing: 20) {
                if let book = currentBook {
                    BookCoverView(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        genre: book.genre,
                        cornerRadius: 8
                    )
                    .frame(width: 100, height: 150)
                    .shadow(color: activeGlow.opacity(0.35), radius: 12, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("СЕЙЧАС В ЧТЕНИИ")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(activeGlow.opacity(0.85))
                            .tracking(2)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Text(book.typographicTitle)
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(book.typographicAuthor)
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundColor(Color.white.opacity(0.72))
                            .lineLimit(1)

                        Spacer().frame(height: 4)

                        HStack(spacing: 6) {
                            Text("\(book.pagesRead)/\(book.totalPages) стр.")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(activeGlow)
                                .lineLimit(1)

                            Text("•")
                                .foregroundColor(.white.opacity(0.3))

                            Text("\(Int(book.progressPercent))%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }

                        GeometryReader { barGeo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                Capsule()
                                    .fill(activeGlow)
                                    .frame(width: max(4, barGeo.size.width * CGFloat(min(1.0, book.progressPercent / 100.0))))
                            }
                        }
                        .frame(height: 4)
                        .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 36))
                            .foregroundColor(activeGlow.opacity(0.5))
                        Text("Выберите книгу для чтения")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Тонкий вертикальный янтарный разделитель
            Rectangle()
                .fill(activeGlow.opacity(0.2))
                .frame(width: 1, height: 180)

            // Правая секция: Крупные часы и цитата
            VStack(alignment: .leading, spacing: 10) {
                clockDisplay(fontSize: 76)

                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .tracking(0.6)
                    .lineLimit(1)

                VStack(alignment: .leading, spacing: 4) {
                    Text("«\(AuthorTypographerEngine.formatTitle(quoteOfTheDay))»")
                        .font(.system(size: 12, weight: .regular, design: .serif))
                        .foregroundColor(.white.opacity(0.88))
                        .italic()
                        .lineLimit(2)

                    Text("— \(AuthorTypographerEngine.formatAuthor(quoteAuthor))")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .foregroundColor(activeGlow.opacity(0.85))
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 32)
    }

    // MARK: - Атомарный блок часов (Никогда не рвет строки)
    private func clockDisplay(fontSize: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(timeOnlyString)
                .font(.system(size: fontSize, weight: .thin, design: .rounded))
                .foregroundColor(activeGlow)
                .shadow(color: activeGlow.opacity(0.45), radius: 10)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 2) {
                if let period = periodString {
                    Text(period)
                        .font(.system(size: fontSize * 0.22, weight: .semibold, design: .rounded))
                        .foregroundColor(activeGlow.opacity(0.85))
                        .lineLimit(1)
                }
                Text(secondsString)
                    .font(.system(size: fontSize * 0.24, weight: .light, design: .monospaced))
                    .foregroundColor(activeGlow.opacity(0.6))
                    .lineLimit(1)
            }
        }
    }

    private func closeView() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

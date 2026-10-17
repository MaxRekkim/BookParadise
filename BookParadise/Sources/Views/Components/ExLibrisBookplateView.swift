import SwiftUI

/// Персональный экслибрис читателя (Ex Libris Bookplate View)
/// Воссоздает физический книжный знак, гравированный книжный ярлык или сургучную печать на форзаце.
public struct ExLibrisBookplateView: View {
    public let config: ExLibrisConfig
    public var scale: CGFloat = 1.0
    public var showShadow: Bool = true

    public init(config: ExLibrisConfig, scale: CGFloat = 1.0, showShadow: Bool = true) {
        self.config = config
        self.scale = scale
        self.showShadow = showShadow
    }

    public var body: some View {
        let accent = config.embossType.primaryColor

        VStack(spacing: 0) {
            // Внешняя рама книжного ярлыка
            ZStack {
                // Подложка бумаги ярлыка
                RoundedRectangle(cornerRadius: 6 * scale)
                    .fill(config.embossType.backgroundGradient)

                // Тонкая внутренняя декоративная гравированная рамка
                RoundedRectangle(cornerRadius: 4 * scale)
                    .strokeBorder(accent.opacity(config.embossType == .goldLeaf ? 0.75 : 0.45), lineWidth: 1.5 * scale)
                    .padding(6 * scale)

                // Вторая пунктирная рамка
                RoundedRectangle(cornerRadius: 2 * scale)
                    .strokeBorder(
                        accent.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1 * scale, dash: [3 * scale, 2 * scale])
                    )
                    .padding(11 * scale)

                // Угловые декоративные виньетки
                cornerFleurons(accent: accent)

                // Внутреннее геральдическое содержание экслибриса
                VStack(spacing: 8 * scale) {
                    // Верхний титул "EX LIBRIS"
                    HStack(spacing: 6 * scale) {
                        Image(systemName: config.style.icon)
                            .font(.system(size: 9 * scale))
                            .foregroundColor(accent)

                        Text("EX • LIBRIS")
                            .font(.system(size: 13 * scale, weight: .bold, design: .serif))
                            .tracking(3.5 * scale)
                            .foregroundColor(accent)

                        Image(systemName: config.style.icon)
                            .font(.system(size: 9 * scale))
                            .foregroundColor(accent)
                    }
                    .padding(.top, 16 * scale)

                    // Центральный медальон монограммы
                    ZStack {
                        Circle()
                            .strokeBorder(accent.opacity(0.55), lineWidth: 1.5 * scale)
                            .frame(width: 58 * scale, height: 58 * scale)

                        Circle()
                            .strokeBorder(
                                accent.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1 * scale, dash: [2 * scale, 2 * scale])
                            )
                            .frame(width: 50 * scale, height: 50 * scale)

                        Text(config.monogram.uppercased())
                            .font(.system(size: 24 * scale, weight: .semibold, design: .serif))
                            .foregroundColor(accent)
                            .tracking(1.5 * scale)
                    }
                    .padding(.vertical, 4 * scale)

                    // Надпись "ИЗ БИБЛИОТЕКИ" / "EX BIBLIOTHECA"
                    Text("EX BIBLIOTHECA")
                        .font(.system(size: 9 * scale, weight: .semibold, design: .monospaced))
                        .tracking(2.0 * scale)
                        .foregroundColor(accent.opacity(0.7))

                    // Имя владельца книжного знака
                    Text(config.ownerName)
                        .font(.system(size: 14 * scale, weight: .bold, design: .serif))
                        .foregroundColor(accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 16 * scale)

                    // Разделитель-орнамент
                    ornamentalDivider(accent: accent)
                        .frame(width: 80 * scale)

                    // Девиз библиофила (Motto)
                    if !config.motto.isEmpty {
                        Text("«\(config.motto)»")
                            .font(.system(size: 10 * scale, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(accent.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18 * scale)
                    }

                    Spacer()

                    // Нижняя дата основания библиотеки
                    Text("EST. ANNO \(config.establishedYear)")
                        .font(.system(size: 8 * scale, weight: .medium, design: .serif))
                        .tracking(1.5 * scale)
                        .foregroundColor(accent.opacity(0.55))
                        .padding(.bottom, 14 * scale)
                }
            }
            .frame(width: 200 * scale, height: 260 * scale)
            .shadow(
                color: showShadow ? Color.black.opacity(config.embossType == .goldLeaf ? 0.35 : 0.14) : .clear,
                radius: 8 * scale,
                x: 0,
                y: 4 * scale
            )
        }
    }

    // MARK: - Угловые декоративные элементы
    @ViewBuilder
    private func cornerFleurons(accent: Color) -> some View {
        VStack {
            HStack {
                cornerDot(accent: accent)
                Spacer()
                cornerDot(accent: accent)
            }
            Spacer()
            HStack {
                cornerDot(accent: accent)
                Spacer()
                cornerDot(accent: accent)
            }
        }
        .padding(16 * scale)
    }

    private func cornerDot(accent: Color) -> some View {
        Circle()
            .fill(accent.opacity(0.5))
            .frame(width: 4 * scale, height: 4 * scale)
    }

    // MARK: - Орнаментальный разделитель
    private func ornamentalDivider(accent: Color) -> some View {
        HStack(spacing: 4 * scale) {
            Rectangle()
                .fill(accent.opacity(0.35))
                .frame(height: 1 * scale)
            Image(systemName: "rhombus.fill")
                .font(.system(size: 5 * scale))
                .foregroundColor(accent.opacity(0.6))
            Rectangle()
                .fill(accent.opacity(0.35))
                .frame(height: 1 * scale)
        }
    }
}

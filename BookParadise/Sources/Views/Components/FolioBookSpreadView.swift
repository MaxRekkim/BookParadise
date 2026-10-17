import SwiftUI

/// Двухстраничный интерактивный разворот книги (Folio Book Spread View)
/// Воссоздает оптику, верстку и физическую глубину книжного переплета на iPad и Mac Catalyst.
public struct FolioBookSpreadView: View {
    public let spread: FolioSpreadModel
    public let texture: PaperTextureType
    public let font: ReaderFont
    public let fontSize: CGFloat
    public let lineSpacing: CGFloat
    public let onPreviousPage: () -> Void
    public let onNextPage: () -> Void

    public init(
        spread: FolioSpreadModel,
        texture: PaperTextureType,
        font: ReaderFont,
        fontSize: CGFloat,
        lineSpacing: CGFloat,
        onPreviousPage: @escaping () -> Void,
        onNextPage: @escaping () -> Void
    ) {
        self.spread = spread
        self.texture = texture
        self.font = font
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.onPreviousPage = onPreviousPage
        self.onNextPage = onNextPage
    }

    public var body: some View {
        GeometryReader { proxy in
            let isWide = FolioSpreadModel.determineMode(
                containerWidth: proxy.size.width,
                isRegularHorizontalSize: proxy.size.width >= 720
            ) == .twoPageSpread

            if isWide {
                // Двухстраничный разворот (Folio Spread)
                HStack(spacing: 0) {
                    // Левая полоса набора
                    pageColumn(content: spread.leftPage, headerTitle: spread.runningHeaderLeft)
                        .frame(maxWidth: .infinity)

                    // Центральный корешок книги (Spine Crease & Gutter Shadow)
                    spineGutter(height: proxy.size.height)
                        .frame(width: spread.spineGutterWidth)

                    // Правая полоса набора
                    pageColumn(content: spread.rightPage, headerTitle: spread.runningHeaderRight)
                        .frame(maxWidth: .infinity)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width < -50 {
                                onNextPage()
                            } else if value.translation.width > 50 {
                                onPreviousPage()
                            }
                        }
                )
            } else {
                // Одностраничный режим для смартфона
                let activePage = spread.rightPage ?? spread.leftPage
                pageColumn(content: activePage, headerTitle: spread.runningHeaderRight)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    onNextPage()
                                } else if value.translation.width > 50 {
                                    onPreviousPage()
                                }
                            }
                    )
            }
        }
    }

    // MARK: - Отдельная полоса набора (страница книги с колонтитулами)
    @ViewBuilder
    private func pageColumn(content: FolioSpreadModel.PageContent?, headerTitle: String) -> some View {
        VStack(spacing: 12) {
            // Верхний колонтитул (Running Header)
            if !headerTitle.isEmpty {
                Text(headerTitle)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .tracking(1.4)
                    .foregroundColor(texture.textColor.opacity(0.45))
                    .padding(.top, 14)
            } else {
                Spacer().frame(height: 25)
            }

            // Основной текст страницы
            if let page = content {
                ScrollView {
                    Text(page.text)
                        .font(font.font(size: fontSize))
                        .foregroundColor(texture.textColor)
                        .lineSpacing(lineSpacing)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 8)
                }
            } else {
                Spacer()
            }

            // Нижний колонтитул с номером страницы (Folio Number)
            if let page = content {
                Text("\(page.pageNumber)")
                    .font(.system(size: 12, weight: .regular, design: .serif))
                    .foregroundColor(texture.textColor.opacity(0.5))
                    .padding(.bottom, 14)
            } else {
                Spacer().frame(height: 26)
            }
        }
    }

    // MARK: - Оптический градиент корешка книги
    private func spineGutter(height: CGFloat) -> some View {
        ZStack {
            // Внутренняя тень прогиба переплёта (слева направо)
            LinearGradient(
                gradient: Gradient(colors: [
                    texture.spineShadowColor.opacity(0.0),
                    texture.spineShadowColor,
                    Color.black.opacity(0.28),
                    texture.spineShadowColor,
                    texture.spineShadowColor.opacity(0.0)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: height)

            // Тончайшая центральная линия шва переплета
            Rectangle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 1, height: height)
        }
    }
}

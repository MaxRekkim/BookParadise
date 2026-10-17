import SwiftUI

/// Двухстраничный интерактивный разворот книги (Folio Book Spread View)
/// Воссоздает оптику, верстку, тактильную физику 3D-перелистывания страниц и акустический отклик бумаги.
public struct FolioBookSpreadView: View {
    public let spread: FolioSpreadModel
    public let texture: PaperTextureType
    public let font: ReaderFont
    public let fontSize: CGFloat
    public let lineSpacing: CGFloat
    public let onPreviousPage: () -> Void
    public let onNextPage: () -> Void

    // Интерактивное состояние перелистывания страницы
    @State private var dragProgress: CGFloat = 0.0
    @State private var activeDirection: PageFlipDirection = .forward
    @State private var isDragging: Bool = false
    @State private var hasFiredHapticMidway: Bool = false

    @ObservedObject private var audioEngine = TactilePageFlipAudioEngine.shared

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

            let physics = TactilePagePhysicsModel(
                dragProgress: dragProgress,
                direction: activeDirection,
                paperWeight: audioEngine.paperWeight,
                containerWidth: proxy.size.width
            )

            ZStack {
                if isWide {
                    // Разворот фолио (iPad / Mac)
                    wideSpreadLayout(proxy: proxy, physics: physics)
                } else {
                    // Одностраничный режим для смартфона (iPhone)
                    compactSinglePageLayout(proxy: proxy, physics: physics)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        handleDragChanged(value: value, containerWidth: proxy.size.width, isWide: isWide)
                    }
                    .onEnded { value in
                        handleDragEnded(value: value, containerWidth: proxy.size.width, isWide: isWide)
                    }
            )
        }
    }

    // MARK: - Двухстраничный разворот (Folio Spread)
    @ViewBuilder
    private func wideSpreadLayout(proxy: GeometryProxy, physics: TactilePagePhysicsModel) -> some View {
        HStack(spacing: 0) {
            // Левая полоса набора
            ZStack {
                pageColumn(content: spread.leftPage, headerTitle: spread.runningHeaderLeft)
                    .frame(maxWidth: .infinity)

                // Тень при перелистывании назад (слева направо)
                if isDragging && activeDirection == .backward {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(physics.shadowOpacity),
                            Color.clear
                        ]),
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
                }
            }

            // Центральный корешок книги (Spine Crease & Gutter Shadow)
            spineGutter(height: proxy.size.height)
                .frame(width: spread.spineGutterWidth)

            // Правая полоса набора
            ZStack {
                pageColumn(content: spread.rightPage, headerTitle: spread.runningHeaderRight)
                    .frame(maxWidth: .infinity)

                // Тень под приподнятым листом при перелистывании вперед
                if isDragging && activeDirection == .forward {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(physics.shadowOpacity),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(false)
                }

                // 3D-перелистываемый лист (Peeling Page Leaf)
                if isDragging && activeDirection == .forward {
                    turningLeafOverlay(content: spread.rightPage, headerTitle: spread.runningHeaderRight, physics: physics, isWide: true)
                }
            }
        }
    }

    // MARK: - Одностраничный режим (iPhone)
    @ViewBuilder
    private func compactSinglePageLayout(proxy: GeometryProxy, physics: TactilePagePhysicsModel) -> some View {
        let activePage = spread.rightPage ?? spread.leftPage
        ZStack {
            pageColumn(content: activePage, headerTitle: spread.runningHeaderRight)
                .frame(maxWidth: .infinity)

            // Тень прогиба листа
            if isDragging {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(physics.shadowOpacity * 0.7),
                        Color.clear
                    ]),
                    startPoint: activeDirection == .forward ? .trailing : .leading,
                    endPoint: activeDirection == .forward ? .leading : .trailing
                )
                .allowsHitTesting(false)

                // 3D-перегиб страницы смартфона
                turningLeafOverlay(content: activePage, headerTitle: spread.runningHeaderRight, physics: physics, isWide: false)
            }
        }
    }

    // MARK: - Динамический 3D-лист при перелистывании (Turning Leaf with Specular Highlights)
    @ViewBuilder
    private func turningLeafOverlay(
        content: FolioSpreadModel.PageContent?,
        headerTitle: String,
        physics: TactilePagePhysicsModel,
        isWide: Bool
    ) -> some View {
        ZStack {
            // Подложка бумаги листа
            texture.backgroundColor
                .overlay(
                    // Цилиндрический блик света по гребню перегиба
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(physics.specularHighlightOpacity),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Текст страницы
            if physics.isShowingReverseSide {
                // Обратная сторона листа (Show-through mirror effect)
                pageColumn(content: content, headerTitle: headerTitle)
                    .opacity(0.12)
                    .scaleEffect(x: -1, y: 1) // Зеркальное отражение сквозь бумагу
            } else {
                pageColumn(content: content, headerTitle: headerTitle)
            }
        }
        .frame(maxWidth: .infinity)
        .rotation3DEffect(
            .degrees(physics.rotationAngle),
            axis: (x: 0.0, y: 1.0, z: 0.0),
            anchor: activeDirection == .forward ? .leading : .trailing,
            perspective: 0.4
        )
        .shadow(
            color: Color.black.opacity(physics.shadowOpacity),
            radius: physics.shadowWidth,
            x: activeDirection == .forward ? -physics.shadowWidth / 2 : physics.shadowWidth / 2,
            y: 0
        )
        .allowsHitTesting(false)
    }

    // MARK: - Обработка интерактивного жеста перелистывания
    private func handleDragChanged(value: DragGesture.Value, containerWidth: CGFloat, isWide: Bool) {
        let translation = value.translation.width
        let halfWidth = isWide ? (containerWidth / 2.0) : containerWidth

        if !isDragging {
            isDragging = true
            hasFiredHapticMidway = false
            activeDirection = translation < 0 ? .forward : .backward
        }

        // Вычисляем прогресс перелистывания от 0.0 до 1.0
        let progress = min(1.0, max(0.0, abs(translation) / max(100.0, halfWidth * 0.9)))
        dragProgress = progress

        // Тактильный щелчок при прохождении центра тяжести листа (50%)
        if progress >= 0.5 && !hasFiredHapticMidway {
            hasFiredHapticMidway = true
            HapticManager.shared.lightTap()
        } else if progress < 0.4 {
            hasFiredHapticMidway = false
        }
    }

    private func handleDragEnded(value: DragGesture.Value, containerWidth: CGFloat, isWide: Bool) {
        let translation = value.translation.width
        let velocity = abs(value.predictedEndTranslation.width - translation)
        let isPastThreshold = dragProgress >= 0.35 || velocity > 180.0

        if isPastThreshold {
            // Доводим анимацию перелистывания до завершения
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                dragProgress = 1.0
            }

            // Акустический шелест бумаги + тактильный отклик
            audioEngine.playPageFlip(velocity: velocity / 100.0)
            HapticManager.shared.mediumTap()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                if activeDirection == .forward {
                    onNextPage()
                } else {
                    onPreviousPage()
                }
                dragProgress = 0.0
                isDragging = false
                hasFiredHapticMidway = false
            }
        } else {
            // Возврат листа на исходную позицию (отмена)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                dragProgress = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isDragging = false
                hasFiredHapticMidway = false
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

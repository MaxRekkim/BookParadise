import SwiftUI

/// Полноэкранный пространственный 3D-инспектор физического книжного тома (Spatial 3D Folio Inspector).
/// Позволяет вертеть и рассматривать книгу в руках со всех сторон:
/// - Аппаратный гироскоп CoreMotion: физический наклон телефона поворачивает книгу в пространстве
/// - Интерактивное 360° вращение пальцем (осмотр обложки, корешка с бинтами, среза страниц и задней крышки)
/// - Выбор благородного золотого или изумрудного обреза страниц (Gilded Edge)
/// - Шелковое ляссе (закладка) и натуральные тени
/// - Тактильные щелчки Taptic Engine при прохождении граней тома
@MainActor
public struct Spatial3DFolioInspectorSheet: View {
    public let book: Book
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var motion = DeviceMotionManager.shared
    @State private var rotationY: Double = 0.0
    @State private var rotationX: Double = 0.0
    @State private var isGyroActive: Bool = true
    @State private var selectedEdgeFinish: PageEdgeFinish = .gildedGold
    @State private var isSpinning: Bool = false

    /// Варианты отделки обреза книжного блока
    public enum PageEdgeFinish: String, CaseIterable, Identifiable {
        case gildedGold = "Золотой обрез"
        case antiqueIvory = "Антикварный лен"
        case emerald = "Изумрудный шелк"

        public var id: String { rawValue }

        public var edgeColors: [Color] {
            switch self {
            case .gildedGold:
                return [
                    Color(red: 0.95, green: 0.82, blue: 0.45),
                    Color(red: 0.82, green: 0.68, blue: 0.32),
                    Color(red: 0.95, green: 0.85, blue: 0.50)
                ]
            case .antiqueIvory:
                return [
                    Color(red: 0.94, green: 0.91, blue: 0.84),
                    Color(red: 0.88, green: 0.84, blue: 0.76),
                    Color(red: 0.94, green: 0.90, blue: 0.83)
                ]
            case .emerald:
                return [
                    Color(red: 0.22, green: 0.55, blue: 0.42),
                    Color(red: 0.15, green: 0.40, blue: 0.30),
                    Color(red: 0.25, green: 0.60, blue: 0.46)
                ]
            }
        }
    }

    public init(book: Book) {
        self.book = book
    }

    /// Толщина блока страниц в зависимости от объема
    private var spineDepth: CGFloat {
        let pages = book.totalPages
        if pages <= 150 { return 24 }
        if pages <= 350 { return 34 }
        if pages <= 600 { return 46 }
        return 58
    }

    /// Результирующий угол Y (палец + гироскоп)
    private var effectiveAngleY: Double {
        if isGyroActive {
            return rotationY + (motion.roll * 32.0)
        }
        return rotationY
    }

    /// Результирующий угол X (палец + гироскоп)
    private var effectiveAngleX: Double {
        if isGyroActive {
            return rotationX + (motion.pitch * 28.0)
        }
        return rotationX
    }

    public var body: some View {
        ZStack {
            // Атмосферный градиент фона библиотеки
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.04, green: 0.05, blue: 0.06),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Шапка инспектора
                headerBar

                Spacer()

                // Центральный 3D-том книги
                threeDimensionalBookVolume
                    .frame(width: 200, height: 300)

                Spacer()

                // Нижняя панель управления и детали тома
                bottomControlsPanel
            }
        }
        .onAppear {
            motion.startUpdates()
        }
        .onDisappear {
            motion.stopUpdates()
        }
    }

    // MARK: - Верхняя панель
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "cube.transparent.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                    Text("3D ФОЛИО-ИНСПЕКТОР")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                        .tracking(1.4)
                }

                Text(book.typographicTitle)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Переключатель гироскопа
            Button(action: {
                isGyroActive.toggle()
                HapticManager.shared.lightTap()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isGyroActive ? "gyroscope" : "hand.draw")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isGyroActive ? "Гироскоп" : "Жест")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(isGyroActive ? .orange : .white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Capsule().stroke(isGyroActive ? Color.orange.opacity(0.4) : Color.white.opacity(0.15), lineWidth: 1))
                )
            }

            // Закрытие
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - 3D Модель книги
    private var threeDimensionalBookVolume: some View {
        ZStack {
            // Глубокая объемная тень под книгой
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.55))
                .frame(width: 190, height: 285)
                .blur(radius: 20)
                .offset(y: 28)

            // Срез страниц (толщина книжного блока)
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: selectedEdgeFinish.edgeColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 195, height: 290)
                    .overlay(
                        // Линии отдельных страниц на срезе
                        HStack(spacing: 2) {
                            ForEach(0..<6, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.06))
                                    .frame(width: 1)
                            }
                        }
                    )
                    .offset(x: spineDepth * 0.4)
            }

            // Лицевая обложка книги
            BookCoverView(
                coverURL: book.cleanCoverURL,
                title: book.title,
                author: book.author,
                genre: book.genre,
                cornerRadius: 12
            )
            .frame(width: 195, height: 290)
            .overlay(
                // Блик по лаку обложки
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color.white.opacity(0.35), location: 0.5 + (effectiveAngleY / 180.0) * 0.4),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
            )

            // Шелковая закладка-ляссе
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.72, green: 0.15, blue: 0.18), Color(red: 0.45, green: 0.08, blue: 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 14, height: 42)
                    .offset(y: 20)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, y: 3)
            }
        }
        // Вращение в 3D пространстве
        .rotation3DEffect(
            .degrees(effectiveAngleY),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            perspective: 0.5
        )
        .rotation3DEffect(
            .degrees(effectiveAngleX),
            axis: (x: -1, y: 0, z: 0),
            anchor: .center,
            perspective: 0.5
        )
        // Жест свободного вращения в руках
        .gesture(
            DragGesture()
                .onChanged { value in
                    let deltaX = Double(value.translation.width * 0.8)
                    let deltaY = Double(value.translation.height * 0.6)
                    rotationY = deltaX
                    rotationX = deltaY
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                        rotationY = 0
                        rotationX = 0
                    }
                    HapticManager.shared.selectionChanged()
                }
        )
        .onTapGesture(count: 2) {
            // Двойной тап для центрирования
            withAnimation(.spring()) {
                rotationY = 0
                rotationX = 0
                motion.recalibrate()
            }
            HapticManager.shared.lightTap()
        }
    }

    // MARK: - Нижняя панель
    private var bottomControlsPanel: some View {
        VStack(spacing: 16) {
            // Выбор отделки обреза страниц
            HStack(spacing: 10) {
                ForEach(PageEdgeFinish.allCases) { finish in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedEdgeFinish = finish
                        }
                        HapticManager.shared.lightTap()
                    }) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(finish.edgeColors[0])
                                .frame(width: 10, height: 10)
                            Text(finish.rawValue)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(selectedEdgeFinish == finish ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedEdgeFinish == finish ? Color.white.opacity(0.12) : Color.clear)
                        )
                    }
                }
            }
            .padding(4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.05))
            )

            // Спецификация физического тома
            HStack(spacing: 24) {
                specItem(title: "Объем", value: "\(book.totalPages) стр.")
                specItem(title: "Толщина блока", value: "~\(Int(spineDepth * 0.65)) мм")
                specItem(title: "Формат", value: book.format.rawValue)
                specItem(title: "Переплет", value: "Твердый №7")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func specItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.45))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

import SwiftUI

/// Интерактивная 3D обложка с аппаратным параллаксом от гироскопа (Spatial Motion-Responsive Book Cover).
/// При повороте и наклоне iPhone:
/// - Книга поворачивается в 3D пространстве с реалистичной перспективой
/// - Динамический голографический/лакированный блик скользит по тиснению обложки
/// - Физическая глубинная тень смещается в сторону, противоположную наклону
/// - Появляется объемная кромка книжного блока (страницы)
/// - Тап по обложке открывает полноэкранный 3D-инспектор тома
@MainActor
public struct Spatial3DBookCoverView: View {
    public let coverURL: URL?
    public let title: String
    public let author: String
    public let genre: Genre
    public var cornerRadius: CGFloat = 12
    public var maxTiltAngle: Double = 18.0
    public var enableTapToInspect: Bool = true
    public var onInspect: (() -> Void)? = nil

    @ObservedObject private var motion = DeviceMotionManager.shared
    @State private var dragOffset: CGSize = .zero

    public init(
        coverURL: URL?,
        title: String,
        author: String = "",
        genre: Genre = .modernProse,
        cornerRadius: CGFloat = 12,
        maxTiltAngle: Double = 18.0,
        enableTapToInspect: Bool = true,
        onInspect: (() -> Void)? = nil
    ) {
        self.coverURL = coverURL
        self.title = title
        self.author = author
        self.genre = genre
        self.cornerRadius = cornerRadius
        self.maxTiltAngle = maxTiltAngle
        self.enableTapToInspect = enableTapToInspect
        self.onInspect = onInspect
    }

    /// Итоговый крен влево/вправо (гироскоп + ручной жест)
    private var effectiveRoll: Double {
        let manual = Double(dragOffset.width / 140.0)
        return max(-1.0, min(1.0, motion.roll + manual))
    }

    /// Итоговый наклон вперед/назад (гироскоп + ручной жест)
    private var effectivePitch: Double {
        let manual = Double(-dragOffset.height / 140.0)
        return max(-1.0, min(1.0, motion.pitch + manual))
    }

    public var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                // 1. Динамическая пространственная тень (смещается в сторону, противоположную наклону)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: width * 0.94, height: height * 0.96)
                    .blur(radius: 10 + abs(effectiveRoll) * 6)
                    .offset(
                        x: -effectiveRoll * 18,
                        y: max(6, -effectivePitch * 18 + 8)
                    )

                // 2. Имитация объема книжного блока (толщина среза страниц при сильном наклоне)
                if abs(effectiveRoll) > 0.06 {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.94, green: 0.90, blue: 0.82),
                                    Color(red: 0.82, green: 0.78, blue: 0.70)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: width, height: height)
                        .offset(x: effectiveRoll > 0 ? 5 : -5, y: 1)
                        .opacity(min(1.0, abs(effectiveRoll) * 1.5))
                }

                // 3. Сама обложка книги
                BookCoverView(
                    coverURL: coverURL,
                    title: title,
                    author: author,
                    genre: genre,
                    cornerRadius: cornerRadius
                )

                // 4. Голографический световой блик (динамически скользит по лакированной обложке)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color.white.opacity(0.0), location: max(0.0, 0.35 + effectiveRoll * 0.35)),
                                .init(color: Color.white.opacity(0.28), location: max(0.0, min(1.0, 0.5 + effectiveRoll * 0.35))),
                                .init(color: Color.white.opacity(0.0), location: min(1.0, 0.65 + effectiveRoll * 0.35)),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: UnitPoint(x: 0.0, y: 0.0),
                            endPoint: UnitPoint(x: 1.0, y: 1.0)
                        )
                    )
                    .blendMode(.screen)
                    .allowsHitTesting(false)

                // 5. Иконка-бейдж 3D инспектора в нижнем правом углу
                if enableTapToInspect {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "cube.transparent")
                                    .font(.system(size: 9, weight: .bold))
                                Text("3D")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.65))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.8))
                            )
                            .padding(6)
                        }
                    }
                }
            }
            // 3D поворот по двум осям (Roll вокруг Y, Pitch вокруг X)
            .rotation3DEffect(
                .degrees(effectiveRoll * maxTiltAngle),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                perspective: 0.45
            )
            .rotation3DEffect(
                .degrees(effectivePitch * maxTiltAngle),
                axis: (x: -1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.45
            )
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.78), value: effectiveRoll)
            .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.78), value: effectivePitch)
            // Жест касания и перетаскивания (для ручной проверки и macOS)
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                            dragOffset = .zero
                        }
                    }
            )
            .onTapGesture {
                if enableTapToInspect {
                    HapticManager.shared.lightTap()
                    onInspect?()
                }
            }
        }
        .onAppear {
            motion.startUpdates()
        }
        .onDisappear {
            motion.stopUpdates()
        }
    }
}

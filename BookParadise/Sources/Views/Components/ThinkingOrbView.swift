import SwiftUI

/// Состояния процедурной анимированной сферы мыслей (Thinking Orb)
public enum ThinkingOrbState: String, CaseIterable, Identifiable {
    case breathing   // Режим глубокого погружения / дзен-дыхание (кольцо волн)
    case searching   // Поиск книги в каталоге / сканирование штрихкода (глобус с меридианом)
    case working     // Фоновая синхронизация / обработка данных (орбиты с частицами)
    case listening   // Концентрация под шум дождя / аудио (сферические волны)
    case solving     // Распознавание цитат Apple Vision / сборка (рубик-сфера)

    public var id: String { rawValue }

    public var localizedDescription: String {
        switch self {
        case .breathing: return "Погружение..."
        case .searching: return "Поиск книги..."
        case .working:   return "Синхронизация..."
        case .listening: return "Концентрация..."
        case .solving:   return "Распознавание..."
        }
    }
}

/// Точка на 2D-холсте, спроецированная из 3D-пространства
struct OrbDot {
    var x: Double
    var y: Double
    var z: Double
    var r: Double
    var white: Double // 0.0 = самый тёмный, 1.0 = самый светлый
    var a: Double     // альфа
}

/// Высокопроизводительный компонент процедурных сфер (на чистом SwiftUI Canvas + TimelineView)
public struct ThinkingOrbView: View {
    public let state: ThinkingOrbState
    public let size: CGFloat
    public let speedMultiplier: Double
    public let tintColor: Color?
    public let isPaused: Bool

    @Environment(\.colorScheme) private var colorScheme

    public init(
        state: ThinkingOrbState = .breathing,
        size: CGFloat = 64,
        speedMultiplier: Double = 1.0,
        tintColor: Color? = nil,
        isPaused: Bool = false
    ) {
        self.state = state
        self.size = size
        self.speedMultiplier = speedMultiplier
        self.tintColor = tintColor
        self.isPaused = isPaused
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: isPaused)) { timeline in
            Canvas { context, canvasSize in
                let targetSize = min(canvasSize.width, canvasSize.height)
                guard targetSize > 2 else { return }

                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let t = elapsed * speedMultiplier
                let isDark = (colorScheme == .dark)

                let dots = generateFrame(state: state, size: targetSize, t: t)

                for dot in dots {
                    guard dot.a >= 0.02 else { continue }
                    let clampedWhite = min(1.0, max(0.0, dot.white))
                    
                    let fillColor: Color
                    if let tint = tintColor {
                        // Кастомный акцент с сохранением глубины через прозрачность
                        let depthAlpha = dot.a * (0.35 + 0.65 * (isDark ? clampedWhite : (1.0 - clampedWhite)))
                        fillColor = tint.opacity(depthAlpha)
                    } else {
                        // Адаптивный монохром (как в оригинале thinking-orbs)
                        let grayLevel = isDark ? (1.0 - clampedWhite) : clampedWhite
                        fillColor = Color(
                            red: grayLevel,
                            green: grayLevel,
                            blue: grayLevel
                        ).opacity(dot.a)
                    }

                    let rect = CGRect(
                        x: dot.x - dot.r,
                        y: dot.y - dot.r,
                        width: dot.r * 2,
                        height: dot.r * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(fillColor))
                }
            }
            .frame(width: size, height: size)
        }
    }

    // MARK: - Генерация кадров геометрии

    private func generateFrame(state: ThinkingOrbState, size: Double, t: Double) -> [OrbDot] {
        var dots: [OrbDot] = []
        switch state {
        case .breathing:
            dots = frameBreathing(size: size, t: t * 1.8)
        case .searching:
            dots = frameSearching(size: size, t: t * 1.5)
        case .working:
            dots = frameWorking(size: size, t: t * 1.4)
        case .listening:
            dots = frameListening(size: size, t: t * 2.0)
        case .solving:
            dots = frameSolving(size: size, t: t * 1.2)
        }

        // Z-сортировка: от дальних к ближним
        dots.sort { $0.z < $1.z }
        return dots
    }

    // MARK: - Режим Дыхания (Breathing / Ring Morph)
    private func frameBreathing(size: Double, t: Double) -> [OrbDot] {
        let cx = size / 2.0
        let cy = size / 2.0
        let R = (size / 2.0) * 0.78
        let camTilt = 0.3
        let proj = makeProj(yaw: 0, tilt: -camTilt, cx: cx, cy: cy, scale: 1.0)
        let rs = pow(size / 300.0, 0.6)

        var dots: [OrbDot] = []
        let wobAmp = 0.23 * 0.6
        let baseR = R / (1.0 + 0.85 * wobAmp)
        let lanes = size > 40 ? 5 : 3
        let segs = size > 40 ? 80 : 36

        for w in 0..<lanes {
            let laneOff = (Double(w) - Double(lanes - 1) / 2.0) * 0.08
            let edge = abs(Double(w) - Double(lanes - 1) / 2.0) / max(1.0, Double(lanes - 1) / 2.0)

            for k in 0..<segs {
                let a = (Double(k) / Double(segs)) * 2.0 * .pi
                let wob = (0.16 * sin(a * 3.0 - t * 1.7 + Double(w) * 0.22) + 0.07 * sin(a * 5.0 + t * 1.1)) * 0.65
                let radial = 1.0 + wob
                let x = cos(a)
                let y = sin(a)
                let z = laneOff

                let l = max(1e-5, sqrt(x * x + y * y + z * z))
                let rr = baseR * radial
                let (px, py, zr) = proj(x / l * rr, y / l * rr, z / l * rr)
                let depth = (zr / R + 1.0) / 2.0

                dots.append(OrbDot(
                    x: px,
                    y: py,
                    z: zr,
                    r: max(0.5, (1.1 + 1.7 * depth) * (1.0 - 0.25 * edge) * rs * (size > 40 ? 1.0 : 1.5)),
                    white: 0.52 - 0.44 * depth + 0.18 * edge,
                    a: 0.4 + 0.6 * depth
                ))
            }
        }
        return dots
    }

    // MARK: - Режим Поиска (Searching / Globe Scan)
    private func frameSearching(size: Double, t: Double) -> [OrbDot] {
        let cx = size / 2.0
        let cy = size / 2.0
        let radius = (size / 2.0) * 0.82
        let spin = 0.5
        let tilt = 0.4 + 0.06 * sin(t * 0.35)
        let proj = makeProj(yaw: t * spin, tilt: tilt, cx: cx, cy: cy, scale: radius)
        let scan = t * (spin + (1.7 - spin) * 4.0)
        let rs = pow(size / 300.0, 0.6)

        var dots: [OrbDot] = []
        let latRings = size > 40 ? 15 : 8
        let lonDensity = size > 40 ? 38 : 18

        for li in 0...latRings {
            let lat = -.pi / 2.0 + (Double(li) / Double(latRings)) * .pi
            let cosLat = cos(lat)
            let sinLat = sin(lat)
            let lonCount = max(1, Int(round(abs(cosLat) * Double(lonDensity))))

            for lj in 0..<lonCount {
                let lon = (Double(lj) / Double(lonCount)) * 2.0 * .pi
                let (px, py, z) = proj(cosLat * cos(lon), sinLat, cosLat * sin(lon))
                let depth = (z + 1.0) / 2.0

                let delta = angleDelta(lon + t * spin, scan)
                let boost = exp(-(delta * delta) / 0.18) * max(0.0, z)

                dots.append(OrbDot(
                    x: px,
                    y: py,
                    z: z,
                    r: max(0.4, (0.6 + 1.6 * depth + 1.0 * boost) * rs * (size > 40 ? 1.0 : 1.5)),
                    white: 0.62 - 0.54 * depth,
                    a: 0.4 + 0.6 * min(1.0, boost)
                ))
            }
        }
        return dots
    }

    // MARK: - Режим Работы / Синхронизации (Working / Tilted Orbits)
    private func frameWorking(size: Double, t: Double) -> [OrbDot] {
        let cx = size / 2.0
        let cy = size / 2.0
        let R = (size / 2.0) * 0.82
        let proj = makeProj(yaw: t * 0.12, tilt: 0.3, cx: cx, cy: cy, scale: 1.0)
        let rs = pow(size / 300.0, 0.6)

        var dots: [OrbDot] = []
        let orbitN = size > 40 ? 8 : 4
        let ghostN = size > 40 ? 28 : 12
        let particles = size > 40 ? 3 : 2

        for orb in 0..<orbitN {
            let h1 = hashDeterministic(Double(orb), 1.7)
            let h2 = hashDeterministic(Double(orb), 5.2)
            let h3 = hashDeterministic(Double(orb), 8.9)
            let ro = R * (0.45 + 0.52 * h1)
            let th = h1 * 2.0 * .pi
            let phi = acos(2.0 * h2 - 1.0)

            let nx = sin(phi) * cos(th)
            let ny = cos(phi)
            let nz = sin(phi) * sin(th)

            var ux = -ny
            var uy = nx
            let uz = 0.0
            let ul = max(1e-6, sqrt(ux * ux + uy * uy))
            ux /= ul
            uy /= ul

            let vx = ny * uz - nz * uy
            let vy = nz * ux - nx * uz
            let vz = nx * uy - ny * ux
            let speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1.0 : -1.0)

            // Призрачная траектория (ghost path)
            for k in 0..<ghostN {
                let a = (Double(k) / Double(ghostN)) * 2.0 * .pi
                let px3 = (ux * cos(a) + vx * sin(a)) * ro
                let py3 = (uy * cos(a) + vy * sin(a)) * ro
                let pz3 = (uz * cos(a) + vz * sin(a)) * ro
                let (px, py, z) = proj(px3, py3, pz3)
                let depth = (z / ro + 1.0) / 2.0

                dots.append(OrbDot(
                    x: px,
                    y: py,
                    z: z,
                    r: max(0.3, 0.85 * rs * (size > 40 ? 1.0 : 1.4)),
                    white: 0.72,
                    a: 0.35 * (0.4 + 0.6 * depth)
                ))
            }

            // Активные вращающиеся частицы
            for m in 0..<particles {
                let a = t * speed + (Double(m) / Double(particles)) * 2.0 * .pi + h2 * 6.0
                let px3 = (ux * cos(a) + vx * sin(a)) * ro
                let py3 = (uy * cos(a) + vy * sin(a)) * ro
                let pz3 = (uz * cos(a) + vz * sin(a)) * ro
                let (px, py, z) = proj(px3, py3, pz3)
                let depth = (z / ro + 1.0) / 2.0

                dots.append(OrbDot(
                    x: px,
                    y: py,
                    z: z,
                    r: max(0.6, (1.2 + 1.6 * depth) * rs * (size > 40 ? 1.0 : 1.8)),
                    white: 0.3 - 0.22 * depth,
                    a: 0.9
                ))
            }
        }
        return dots
    }

    // MARK: - Режим Волн / Концентрации (Listening / Spherical Wave)
    private func frameListening(size: Double, t: Double) -> [OrbDot] {
        let cx = size / 2.0
        let cy = size / 2.0
        let R = (size / 2.0) * 0.85
        let proj = makeProj(yaw: t * 0.18, tilt: 0.38, cx: cx, cy: cy, scale: 1.0)
        let rs = pow(size / 300.0, 0.6)

        var dots: [OrbDot] = []
        let rings = size > 40 ? 14 : 7
        let lonDensity = size > 40 ? 36 : 16

        for ri in 0...rings {
            let lat = -.pi / 2.0 + (Double(ri) / Double(rings)) * .pi
            let cosLat = cos(lat)
            let sinLat = sin(lat)
            let w = 0.62 * sin(t * 2.1 - Double(ri) * 0.52) + 0.38 * sin(t * 1.27 + Double(ri) * 0.83)
            let rr = R * (0.88 + 0.105 * w)
            let lonCount = max(1, Int(round(abs(cosLat) * Double(lonDensity))))

            for lj in 0..<lonCount {
                let lon = (Double(lj) / Double(lonCount)) * 2.0 * .pi
                let (px, py, z) = proj(cosLat * cos(lon) * rr, sinLat * rr, cosLat * sin(lon) * rr)
                let depth = (z / R + 1.0) / 2.0
                let crest = max(0.0, w)

                dots.append(OrbDot(
                    x: px,
                    y: py,
                    z: z,
                    r: max(0.4, (0.6 + 1.7 * depth) * (1.0 + 0.4 * crest) * rs * (size > 40 ? 1.0 : 1.5)),
                    white: 0.66 - 0.56 * depth - 0.1 * crest,
                    a: 0.4 + 0.6 * depth
                ))
            }
        }
        return dots
    }

    // MARK: - Режим Сборки / OCR (Solving / Rubik Grid)
    private func frameSolving(size: Double, t: Double) -> [OrbDot] {
        let cx = size / 2.0
        let cy = size / 2.0
        let R = (size / 2.0) * 0.82
        let proj = makeProj(yaw: t * 0.45, tilt: 0.35 + 0.1 * sin(t * 0.9), cx: cx, cy: cy, scale: R)
        let rs = pow(size / 300.0, 0.6)

        var dots: [OrbDot] = []
        let latRings = size > 40 ? 12 : 7
        let lonDensity = size > 40 ? 32 : 16

        for li in 0...latRings {
            let lat = -.pi / 2.0 + (Double(li) / Double(latRings)) * .pi
            let cosLat = cos(lat)
            let sinLat = sin(lat)
            let lonCount = max(1, Int(round(abs(cosLat) * Double(lonDensity))))

            let bandTwist = sin(t * 1.5 + Double(li) * 0.4) * 0.3

            for lj in 0..<lonCount {
                let lon = (Double(lj) / Double(lonCount)) * 2.0 * .pi + bandTwist
                let (px, py, z) = proj(cosLat * cos(lon), sinLat, cosLat * sin(lon))
                let depth = (z + 1.0) / 2.0

                dots.append(OrbDot(
                    x: px,
                    y: py,
                    z: z,
                    r: max(0.4, (0.6 + 1.7 * depth) * rs * (size > 40 ? 1.0 : 1.4)),
                    white: 0.62 - 0.54 * depth,
                    a: 0.4 + 0.6 * depth
                ))
            }
        }
        return dots
    }

    // MARK: - Вспомогательные математические функции

    private func makeProj(yaw: Double, tilt: Double, cx: Double, cy: Double, scale: Double) -> (Double, Double, Double) -> (Double, Double, Double) {
        let st = sin(tilt)
        let ct = cos(tilt)
        let sy = sin(yaw)
        let cyw = cos(yaw)
        return { x, y, z in
            let x1 = x * cyw + z * sy
            let z1 = -x * sy + z * cyw
            let y1 = y * ct - z1 * st
            let z2 = y * st + z1 * ct
            return (cx + x1 * scale, cy - y1 * scale, z2)
        }
    }

    private func hashDeterministic(_ a: Double, _ b: Double) -> Double {
        let h = sin(a * 12.9898 + b * 78.233) * 43758.5453
        return h - floor(h)
    }

    private func angleDelta(_ a: Double, _ b: Double) -> Double {
        atan2(sin(a - b), cos(a - b))
    }
}

import SwiftUI
import Darwin

/// Пульт бинаурального фокуса и умного таймера затухания (Soundscape Binaural Sheet)
/// Генерирует звуковые частоты для синхронизации мозговых ритмов во время чтения.
public struct SoundscapeBinauralSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var soundscape = SoundscapeManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var selectedBand: BinauralFocusEngine.BrainwaveBand = .alpha
    @State private var isBinauralEnabled: Bool = false
    @State private var binauralVolume: Float = 0.4
    @State private var sleepTimerMinutes: Int = 30
    @State private var isTimerActive: Bool = false
    @State private var phase: Double = 0.0

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Анимация осциллографа частоты
                Section {
                    VStack(spacing: 12) {
                        BrainwaveOscilloscopeView(frequency: selectedBand.beatFrequency, isRunning: isBinauralEnabled)
                            .frame(height: 70)
                            .padding(.vertical, 8)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedBand.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(selectedBand.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $isBinauralEnabled)
                                .labelsHidden()
                                .onChange(of: isBinauralEnabled) { enabled in
                                    HapticManager.shared.lightTap()
                                }
                        }
                    }
                }

                // MARK: - Выбор частотного диапазона
                Section(header: Text("Частотный ритм мозга")) {
                    ForEach(BinauralFocusEngine.BrainwaveBand.allCases) { band in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(band.title)
                                    .font(.subheadline)
                                    .fontWeight(selectedBand == band ? .semibold : .regular)
                                    .foregroundColor(.primary)
                                Text("Несущая: \(Int(band.baseFrequency)) Гц • Разность: +\(String(format: "%.1f", band.beatFrequency)) Гц")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedBand == band {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.primaryAccent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBand = band
                            HapticManager.shared.selectionChanged()
                        }
                    }
                }

                // MARK: - Громкость бинаурального слоя
                if isBinauralEnabled {
                    Section(header: Text("Громкость бинаурального потока")) {
                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: "speaker.wave.1.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Slider(value: $binauralVolume, in: 0.05...1.0)
                                    .tint(theme.primaryAccent)
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("\(Int(binauralVolume * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // MARK: - Таймер сна с экспоненциальным затуханием
                Section(
                    header: Text("Таймер сна (экспоненциальное угасание)"),
                    footer: Text("Громкость плавно снижается по формуле V(t) = V₀ · (1 - t/T)¹·⁶, не прерывая засыпание.")
                ) {
                    Picker("Длительность", selection: $sleepTimerMinutes) {
                        Text("15 минут").tag(15)
                        Text("30 минут").tag(30)
                        Text("45 минут").tag(45)
                        Text("60 минут").tag(60)
                    }
                    .pickerStyle(.segmented)

                    Toggle("Активировать таймер сна", isOn: $isTimerActive)
                        .tint(theme.primaryAccent)
                        .onChange(of: isTimerActive) { active in
                            HapticManager.shared.lightTap()
                        }
                }
            }
            .navigationTitle("Бинауральный фокус")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

/// Анимированный холст визуализации гармонической волны
public struct BrainwaveOscilloscopeView: View {
    public let frequency: Double
    public let isRunning: Bool
    @State private var phase: Double = 0.0

    public var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2.0
                let amplitude = isRunning ? height * 0.35 : height * 0.08

                var path = Path()
                let points = 80
                let dx = width / CGFloat(points)

                for i in 0...points {
                    let x = CGFloat(i) * dx
                    let relativeX = Double(i) / Double(points)
                    let currentPhase = isRunning ? timeline.date.timeIntervalSinceReferenceDate * (frequency * 0.25) : 0
                    let y = midY + CGFloat(Darwin.sin(Double(relativeX) * Double.pi * 4.0 + currentPhase)) * amplitude

                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }

                context.stroke(
                    path,
                    with: .color(isRunning ? Color(red: 0.52, green: 0.14, blue: 0.20) : Color.gray.opacity(0.4)),
                    style: StrokeStyle(lineWidth: isRunning ? 2.5 : 1.5, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}

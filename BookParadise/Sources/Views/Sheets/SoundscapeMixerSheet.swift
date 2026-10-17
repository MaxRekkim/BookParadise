import SwiftUI

public struct SoundscapeMixerSheet: View {
    @ObservedObject private var soundManager = SoundscapeManager.shared
    @Environment(\.dismiss) private var dismiss
    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init() {}

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Главная карточка статуса воспроизведения
                    VStack(spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(wineAccent.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: soundManager.isPlaying ? "waveform" : "speaker.slash")
                                    .font(.title2)
                                    .foregroundColor(wineAccent)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(soundManager.isPlaying ? "Звуковая студия активна" : "Студия на паузе")
                                    .font(.headline)
                                Text("Процедурный многоканальный синтез 2.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                soundManager.togglePlayback()
                                HapticManager.shared.mediumTap()
                            } label: {
                                Image(systemName: soundManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(wineAccent)
                            }
                        }

                        // Мастер громкость
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Общая громкость")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(soundManager.volume * 100))%")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            Slider(value: $soundManager.volume, in: 0...1)
                                .tint(wineAccent)
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Пресеты атмосферы
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ГОТОВЫЕ АТМОСФЕРЫ")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(soundManager.presets) { preset in
                                    Button {
                                        soundManager.applyPreset(preset)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: preset.icon)
                                                .foregroundColor(wineAccent)
                                            Text(preset.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(UIColor.secondarySystemBackground))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                                    }
                                }
                            }
                        }
                    }

                    // 4 Канала микшера
                    VStack(spacing: 14) {
                        Text("КАНАЛЫ МИКШЕРА")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)

                        channelRow(
                            title: "Дождь за окном",
                            icon: "cloud.rain.fill",
                            color: .blue,
                            binding: $soundManager.rainVolume
                        )

                        channelRow(
                            title: "Камин в библиотеке",
                            icon: "flame.fill",
                            color: .orange,
                            binding: $soundManager.fireplaceVolume
                        )

                        channelRow(
                            title: "Уютная кофейня",
                            icon: "cup.and.saucer.fill",
                            color: Color(red: 0.6, green: 0.4, blue: 0.2),
                            binding: $soundManager.coffeehouseVolume
                        )

                        channelRow(
                            title: "Лесной бриз",
                            icon: "leaf.fill",
                            color: .green,
                            binding: $soundManager.forestVolume
                        )
                    }
                    .padding(16)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
            .navigationTitle("Студия звука")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(wineAccent)
                }
            }
        }
    }

    private func channelRow(title: String, icon: String, color: Color, binding: Binding<Float>) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 22)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(binding.wrappedValue * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }

            Slider(value: binding, in: 0...1) { _ in
                if !soundManager.isPlaying && binding.wrappedValue > 0.05 {
                    soundManager.togglePlayback()
                }
            }
            .tint(color)
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI

/// Интерактивный нейро-пейсер и тренажёр скорочтения RSVP (Bionic Neuro-Pacer)
/// Позволяет читать со скоростью до 800 слов в минуту без усталости глаз, удерживая фокус на точке ORP.
public struct BionicNeuroPacerView: View {
    public let text: String
    public let bookTitle: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared

    @State private var words: [NeuroPacerEngine.TokenizedWord] = []
    @State private var currentIndex: Int = 0
    @State private var isPlaying: Bool = false
    @State private var targetWPM: Double = 320.0
    @State private var fixationStrength: NeuroPacerEngine.FixationStrength = .balanced
    @State private var isRulerMode: Bool = false
    @State private var activeLineIndex: Int = 0
    @State private var timer: Timer?

    public init(text: String, bookTitle: String) {
        self.text = text
        self.bookTitle = bookTitle
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.paperBackground(for: .dark)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Переключатель режима: RSVP (Скорочтение) vs Фокус-линейка
                    Picker("Режим", selection: $isRulerMode) {
                        Text("RSVP Скорочтение").tag(false)
                        Text("Фокус-линейка").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    if !isRulerMode {
                        rsvpViewport
                    } else {
                        rulerViewport
                    }

                    Spacer()

                    // Панель управления и настроек
                    controlPanel
                }
            }
            .navigationTitle("Нейро-пейсер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        stopPlayback()
                        dismiss()
                    }
                }
            }
            .onAppear {
                prepareWords()
            }
            .onDisappear {
                stopPlayback()
            }
        }
    }

    // MARK: - RSVP Вьюпорт с центрированием точки ORP
    private var rsvpViewport: some View {
        VStack(spacing: 24) {
            Spacer()

            if words.isEmpty {
                Text("Текст загружается...")
                    .foregroundColor(.secondary)
            } else {
                let currentWord = words[min(currentIndex, words.count - 1)]

                ZStack {
                    // Фоновая направляющая сетка визира
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(theme.primaryAccent.opacity(0.35))
                            .frame(width: 2, height: 16)
                        Spacer()
                            .frame(height: 70)
                        Rectangle()
                            .fill(theme.primaryAccent.opacity(0.35))
                            .frame(width: 2, height: 16)
                    }

                    // Слово с подсвеченным символом ORP
                    HStack(spacing: 0) {
                        let chars = Array(currentWord.fullWord)
                        let orp = currentWord.optimalRecognitionIndex

                        ForEach(0..<chars.count, id: \.self) { idx in
                            let ch = String(chars[idx])
                            if idx == orp {
                                Text(ch)
                                    .font(.system(size: 42, weight: .black, design: .serif))
                                    .foregroundColor(theme.primaryAccent)
                            } else if idx < currentWord.boldPrefix.count {
                                Text(ch)
                                    .font(.system(size: 40, weight: .bold, design: .serif))
                                    .foregroundColor(.primary)
                            } else {
                                Text(ch)
                                    .font(.system(size: 40, weight: .regular, design: .serif))
                                    .foregroundColor(.primary.opacity(0.85))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(theme.cardBorder(for: .dark), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                // Прогресс по словам
                VStack(spacing: 6) {
                    ProgressView(value: Double(currentIndex), total: Double(max(1, words.count - 1)))
                        .tint(theme.primaryAccent)
                        .padding(.horizontal, 24)

                    HStack {
                        Text("Слово \(currentIndex + 1) из \(words.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(targetWPM)) слов/мин")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(theme.primaryAccent)
                    }
                    .padding(.horizontal, 24)
                }
            }

            Spacer()
        }
    }

    // MARK: - Режим фокус-линейки (чтение абзацев без блуждания взгляда)
    private var rulerViewport: some View {
        ScrollViewReader { proxy in
            ScrollView {
                let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(0..<lines.count, id: \.self) { idx in
                        let isFocused = idx == activeLineIndex

                        Text(lines[idx])
                            .font(.system(size: 19, weight: isFocused ? .semibold : .regular, design: .serif))
                            .lineSpacing(6)
                            .foregroundColor(isFocused ? .primary : .secondary.opacity(0.35))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isFocused ? theme.primaryAccent.opacity(0.12) : Color.clear)
                            )
                            .id(idx)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    activeLineIndex = idx
                                    HapticManager.shared.lightTap()
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Панель управления скоростью и воспроизведением
    private var controlPanel: some View {
        VStack(spacing: 16) {
            if !isRulerMode {
                // Кнопки плеера
                HStack(spacing: 36) {
                    Button(action: rewindWords) {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(theme.primaryAccent)
                    }

                    Button(action: forwardWords) {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }

                // Слайдер WPM
                VStack(spacing: 4) {
                    HStack {
                        Text("Скорость нейро-потока:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(targetWPM)) WPM")
                            .font(.caption)
                            .bold()
                            .foregroundColor(theme.primaryAccent)
                    }
                    Slider(value: $targetWPM, in: 120...750, step: 10) { _ in
                        if isPlaying {
                            scheduleNextWord()
                        }
                    }
                    .tint(theme.primaryAccent)
                }
                .padding(.horizontal, 24)
            } else {
                // Управление шагом фокус-линейки
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation {
                            activeLineIndex = max(0, activeLineIndex - 1)
                            HapticManager.shared.lightTap()
                        }
                    }) {
                        Label("Строка назад", systemImage: "arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        withAnimation {
                            activeLineIndex += 1
                            HapticManager.shared.lightTap()
                        }
                    }) {
                        Label("Строка вперед", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    // MARK: - Логика обработки и таймера
    private func prepareWords() {
        let rawTokens = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        self.words = rawTokens.map { NeuroPacerEngine.processWord($0, strength: fixationStrength) }
        self.currentIndex = 0
    }

    private func togglePlayPause() {
        isPlaying.toggle()
        HapticManager.shared.lightTap()
        if isPlaying {
            scheduleNextWord()
        } else {
            stopPlayback()
        }
    }

    private func scheduleNextWord() {
        timer?.invalidate()
        guard isPlaying, currentIndex < words.count else {
            isPlaying = false
            return
        }

        let currentWord = words[currentIndex]
        let delayMs = NeuroPacerEngine.millisecondInterval(for: Int(targetWPM), multiplier: currentWord.durationMultiplier)

        timer = Timer.scheduledTimer(withTimeInterval: delayMs / 1000.0, repeats: false) { _ in
            if self.currentIndex < self.words.count - 1 {
                self.currentIndex += 1
                self.scheduleNextWord()
            } else {
                self.isPlaying = false
                HapticManager.shared.notificationSuccess()
            }
        }
    }

    private func stopPlayback() {
        timer?.invalidate()
        timer = nil
    }

    private func rewindWords() {
        currentIndex = max(0, currentIndex - 10)
        HapticManager.shared.lightTap()
    }

    private func forwardWords() {
        currentIndex = min(words.count - 1, currentIndex + 10)
        HapticManager.shared.lightTap()
    }
}

import SwiftUI
import UIKit

public struct ReadingSessionView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    public let book: Book
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var selectedMode: SessionMode = .pomodoro25
    @State private var isShowingFinishDialog: Bool = false
    @State private var endPageInput: String = ""
    @State private var completedRecord: ReadingSessionRecord? = nil

    public init(viewModel: LibraryViewModel, book: Book) {
        self.viewModel = viewModel
        self.book = book
    }

    private var displaySeconds: Int {
        if sessionManager.currentMode == .stopwatch {
            return sessionManager.elapsedSeconds
        } else {
            return sessionManager.remainingSeconds
        }
    }

    private var timeString: String {
        let minutes = displaySeconds / 60
        let seconds = displaySeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var progressValue: Double {
        if sessionManager.currentMode == .stopwatch {
            return 1.0
        }
        let total = Double(max(1, sessionManager.currentMode.initialSeconds))
        let remaining = Double(sessionManager.remainingSeconds)
        return (total - remaining) / total
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.paperBackground
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Верхний блок с информацией о книге
                    bookHeader
                        .padding(.top, 10)

                    // Выбор режима (если таймер не запущен)
                    if !sessionManager.isRunning {
                        Picker("Режим", selection: $selectedMode) {
                            ForEach(SessionMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                    }

                    Spacer()

                    // Главный круговой таймер
                    timerCircle

                    Spacer()

                    // Кнопка включения фонового звука дождя для концентрации
                    ambientSoundToggle

                    // Панель управления (Старт / Пауза / Завершить)
                    controlButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Сессия чтения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        if sessionManager.isRunning {
                            sessionManager.stopSession()
                        }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingFinishDialog) {
                finishSessionSheet
            }
        }
    }

    // MARK: - Хедер книги
    private var bookHeader: some View {
        HStack(spacing: 14) {
            BookCoverView(
                coverURL: book.cleanCoverURL,
                title: book.title,
                author: book.author,
                genre: book.genre,
                cornerRadius: 8
            )
            .frame(width: 50, height: 75)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundColor(theme.primaryAccent)
                    Text("Начало: \(book.pagesRead) стр. из \(book.totalPages)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .padding(.horizontal, 20)
    }

    // MARK: - Круговой индикатор таймера
    private var timerCircle: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(theme.primaryAccent.opacity(0.12), lineWidth: 14)
                .frame(width: 250, height: 250)

            // Прогресс круг
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    LinearGradient(
                        colors: [theme.primaryAccent, theme.secondaryAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progressValue)
                .frame(width: 250, height: 250)

            // Текст внутри
            VStack(spacing: 6) {
                Text(timeString)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundColor(Color(UIColor.label))

                Text(sessionManager.isRunning ? (sessionManager.isPaused ? "ПАУЗА" : "ЧТЕНИЕ") : "ГОТОВ")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundColor(theme.primaryAccent)
            }
        }
    }

    // MARK: - Переключатель звука дождя
    private var ambientSoundToggle: some View {
        Button(action: {
            sessionManager.toggleAmbientSound()
        }) {
            HStack(spacing: 8) {
                Image(systemName: sessionManager.isAmbientSoundActive ? "cloud.rain.fill" : "cloud.rain")
                    .font(.subheadline)
                Text(sessionManager.isAmbientSoundActive ? "Звук дождя включён" : "Включить шум дождя (концентрация)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(sessionManager.isAmbientSoundActive ? .white : theme.primaryAccent)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(sessionManager.isAmbientSoundActive ? theme.primaryAccent : theme.primaryAccent.opacity(0.12))
            .cornerRadius(20)
        }
    }

    // MARK: - Кнопки управления
    private var controlButtons: some View {
        HStack(spacing: 16) {
            if !sessionManager.isRunning {
                // Старт
                Button(action: {
                    sessionManager.startSession(book: book, mode: selectedMode)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Начать чтение")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primaryAccent)
                    .cornerRadius(14)
                }
            } else {
                // Пауза / Продолжить
                Button(action: {
                    if sessionManager.isPaused {
                        sessionManager.resumeSession()
                    } else {
                        sessionManager.pauseSession()
                    }
                }) {
                    HStack {
                        Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                        Text(sessionManager.isPaused ? "Продолжить" : "Пауза")
                    }
                    .font(.headline)
                    .foregroundColor(theme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.primaryAccent.opacity(0.15))
                    .cornerRadius(14)
                }

                // Завершить сессию
                Button(action: {
                    sessionManager.pauseSession()
                    endPageInput = "\(book.pagesRead)"
                    isShowingFinishDialog = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Закончить")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(14)
                }
            }
        }
    }

    // MARK: - Окно фиксации результата сессии
    private var finishSessionSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Итоги сессии чтения")) {
                    HStack {
                        Text("Время чтения:")
                        Spacer()
                        Text("\(max(1, sessionManager.elapsedSeconds / 60)) мин")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Text("Было прочитано:")
                        Spacer()
                        Text("\(book.pagesRead) стр.")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Новая страница:")
                        Spacer()
                        TextField("например, \(book.pagesRead + 15)", text: $endPageInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .fontWeight(.bold)
                    }
                }

                if let endPage = Int(endPageInput), endPage >= book.pagesRead {
                    let read = endPage - book.pagesRead
                    let speed = Double(read) / (Double(sessionManager.elapsedSeconds) / 3600.0)

                    Section(header: Text("Аналитика скорости")) {
                        HStack {
                            Text("Прочитано за сессию:")
                            Spacer()
                            Text("+\(read) стр.")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("Скорость чтения:")
                            Spacer()
                            Text(String(format: "%.0f стр./час", speed))
                                .fontWeight(.heavy)
                                .foregroundColor(theme.primaryAccent)
                        }
                    }
                }
            }
            .navigationTitle("Сохранить результат")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        isShowingFinishDialog = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if let endPage = Int(endPageInput) {
                            let rec = sessionManager.completeSession(endPage: endPage)
                            self.completedRecord = rec
                            viewModel.updateBookProgress(bookId: book.id, pagesRead: endPage)
                        }
                        isShowingFinishDialog = false
                        dismiss()
                    }
                }
            }
        }
    }
}

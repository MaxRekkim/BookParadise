import SwiftUI
import UIKit

public struct ReadingSessionView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    public let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var isShowingFinishDialog: Bool = false
    @State private var endPageInput: String = ""
    @State private var completedRecord: ReadingSessionRecord? = nil

    public init(viewModel: LibraryViewModel, book: Book) {
        self.viewModel = viewModel
        self.book = book
    }

    private var timeString: String {
        let hours = sessionManager.elapsedSeconds / 3600
        let minutes = (sessionManager.elapsedSeconds % 3600) / 60
        let seconds = sessionManager.elapsedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.paperBackground(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Верхний блок книги
                    bookHeader
                        .padding(.top, 12)

                    Spacer()

                    // Центральная часть: сфера Thinking Orb и время сессии
                    zenReadingOrb

                    Spacer()

                    // Панель управления (Начать чтение / Пауза / Завершить)
                    controlButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
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
            .frame(width: 48, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                    .lineLimit(1)

                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundColor(theme.primaryAccent)
                    Text("Начало: \(book.pagesRead) из \(book.totalPages) стр.")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Дзен-сфера и секундомер чтения
    private var zenReadingOrb: some View {
        VStack(spacing: 20) {
            ZStack {
                // Анимированная сфера ThinkingOrb
                ThinkingOrbView(
                    state: sessionManager.isRunning ? (sessionManager.isPaused ? .searching : .listening) : .breathing,
                    size: 250,
                    speedMultiplier: sessionManager.isPaused ? 0.35 : (sessionManager.isRunning ? 1.0 : 0.6),
                    tintColor: theme.primaryAccent,
                    isPaused: false
                )

                // Тонкое кольцо концентрации
                Circle()
                    .stroke(theme.primaryAccent.opacity(sessionManager.isRunning ? 0.35 : 0.15), lineWidth: 2)
                    .frame(width: 256, height: 256)

                // Счётчик времени чтения по центру сферы
                VStack(spacing: 6) {
                    Text(timeString)
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor.label))
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.8) : Color.white.opacity(0.8), radius: 4)

                    Text(sessionManager.isRunning ? (sessionManager.isPaused ? "ПАУЗА" : "ЧТЕНИЕ") : "СВОБОДНЫЙ ТЕМП")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(2.5)
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(theme.cardBackground(for: colorScheme).opacity(0.85))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 0.5)
                        )
                }
            }
            .frame(width: 260, height: 260)

            Text("Никакого давления таймеров — читайте в своём ритме")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Кнопки управления сессией
    private var controlButtons: some View {
        HStack(spacing: 14) {
            if !sessionManager.isRunning {
                // Старт
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        sessionManager.startSession(book: book)
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Начать чтение")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.primaryAccent, theme.secondaryAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: theme.primaryAccent.opacity(0.35), radius: 8, x: 0, y: 4)
                }
            } else {
                // Пауза / Возобновить
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if sessionManager.isPaused {
                            sessionManager.resumeSession()
                        } else {
                            sessionManager.pauseSession()
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                        Text(sessionManager.isPaused ? "Продолжить" : "Пауза")
                    }
                    .font(.headline)
                    .foregroundColor(theme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.cardBackground(for: colorScheme))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(theme.primaryAccent.opacity(0.4), lineWidth: 1.5)
                    )
                }

                // Завершить сессию
                Button(action: {
                    sessionManager.pauseSession()
                    endPageInput = "\(book.pagesRead)"
                    isShowingFinishDialog = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Закончить")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(14)
                    .shadow(color: Color.green.opacity(0.35), radius: 6, x: 0, y: 3)
                }
            }
        }
    }

    // MARK: - Диалог фиксации прочитанных страниц
    private var finishSessionSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Итоги сессии чтения")) {
                    HStack {
                        Text("Время чтения:")
                        Spacer()
                        let mins = max(1, sessionManager.elapsedSeconds / 60)
                        Text("\(mins) мин")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Text("Было прочитано:")
                        Spacer()
                        Text("\(book.pagesRead) стр.")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Текущая страница:")
                        Spacer()
                        TextField("например, \(book.pagesRead + 20)", text: $endPageInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                            .fontWeight(.bold)
                    }
                }

                if let endPage = Int(endPageInput), endPage >= book.pagesRead {
                    let read = endPage - book.pagesRead
                    let hours = max(0.01, Double(sessionManager.elapsedSeconds) / 3600.0)
                    let speed = Double(read) / hours

                    Section(header: Text("Темп сессии")) {
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
            .navigationTitle("Сохранить прогресс")
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

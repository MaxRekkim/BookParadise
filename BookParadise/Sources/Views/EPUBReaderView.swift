import SwiftUI

public struct EPUBReaderView: View {
    public let book: Book
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var readerService = EPUBReaderService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var chapters: [ReaderChapter] = []
    @State private var currentChapterIndex: Int = 0
    @State private var showingSettings: Bool = false
    @State private var showingQuoteAlert: Bool = false
    @State private var quickQuoteText: String = ""

    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init(book: Book, viewModel: LibraryViewModel) {
        self.book = book
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            readerService.theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Верхний тулбар
                topBar

                Divider()
                    .opacity(0.3)

                // Текст главы
                if chapters.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Подготовка книги к чтению...")
                            .font(.caption)
                            .foregroundColor(readerService.theme.textColor.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    let chapter = chapters[currentChapterIndex]
                    ScrollView {
                        VStack(alignment: .leading, spacing: readerService.lineSpacing + 10) {
                            Text(chapter.title)
                                .font(readerService.selectedFont.font(size: readerService.fontSize + 8).bold())
                                .foregroundColor(readerService.theme.textColor)
                                .padding(.top, 16)
                                .padding(.bottom, 8)

                            if readerService.isBionicEnabled {
                                let attr = readerService.bionicAttributedString(
                                    from: chapter.content,
                                    baseFont: readerService.selectedFont.font(size: readerService.fontSize),
                                    textColor: readerService.theme.textColor
                                )
                                Text(attr)
                                    .lineSpacing(readerService.lineSpacing)
                            } else {
                                Text(chapter.content)
                                    .font(readerService.selectedFont.font(size: readerService.fontSize))
                                    .foregroundColor(readerService.theme.textColor)
                                    .lineSpacing(readerService.lineSpacing)
                            }

                            // Нижний разделитель и кнопка перехода
                            HStack {
                                if currentChapterIndex > 0 {
                                    Button("← Предыдущая глава") {
                                        currentChapterIndex -= 1
                                        HapticManager.shared.lightTap()
                                    }
                                    .foregroundColor(wineAccent)
                                }

                                Spacer()

                                if currentChapterIndex < chapters.count - 1 {
                                    Button("Следующая глава →") {
                                        currentChapterIndex += 1
                                        HapticManager.shared.lightTap()
                                    }
                                    .foregroundColor(wineAccent)
                                    .fontWeight(.bold)
                                }
                            }
                            .padding(.vertical, 24)
                        }
                        .padding(.horizontal, 22)
                    }
                }

                Divider()
                    .opacity(0.3)

                // Нижняя панель действий и прогресса
                bottomBar
            }
        }
        .onAppear {
            loadBookChapters()
        }
        .sheet(isPresented: $showingSettings) {
            readerSettingsSheet
        }
        .alert("Цитата сохранена", isPresented: $showingQuoteAlert) {
            Button("Отлично", role: .cancel) {}
        } message: {
            Text("Фрагмент успешно добавлен в ваш цитатник.")
        }
    }

    // MARK: - Верхний тулбар
    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(readerService.theme.textColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(readerService.theme.textColor)
                    .lineLimit(1)
                Text(book.author)
                    .font(.system(size: 11))
                    .foregroundColor(readerService.theme.textColor.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Переключатель Bionic Reading
            Button {
                readerService.isBionicEnabled.toggle()
                HapticManager.shared.lightTap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: readerService.isBionicEnabled ? "bolt.fill" : "bolt")
                        .font(.caption2)
                    Text("Bionic")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(readerService.isBionicEnabled ? wineAccent : readerService.theme.textColor.opacity(0.1))
                .foregroundColor(readerService.isBionicEnabled ? .white : readerService.theme.textColor)
                .clipShape(Capsule())
            }

            // Настройки типографики
            Button {
                showingSettings = true
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 16))
                    .foregroundColor(readerService.theme.textColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Нижняя панель
    private var bottomBar: some View {
        HStack {
            if !chapters.isEmpty {
                Text("Глава \(currentChapterIndex + 1) из \(chapters.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(readerService.theme.textColor.opacity(0.8))

                Spacer()

                // Кнопка сохранения цитаты
                Button {
                    saveQuickQuote()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "quote.bubble.fill")
                        Text("В цитатник")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(wineAccent)
                }

                Spacer()

                // Быстрая отметка страниц
                Button {
                    logQuickPages()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                        Text("+5 стр")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(wineAccent.opacity(0.12))
                    .foregroundColor(wineAccent)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Настройки ридера
    private var readerSettingsSheet: some View {
        NavigationView {
            Form {
                Section("Размер текста") {
                    HStack {
                        Text("A")
                            .font(.system(size: 14))
                        Slider(value: $readerService.fontSize, in: 13...28, step: 1)
                            .tint(wineAccent)
                        Text("A")
                            .font(.system(size: 24, weight: .bold))
                    }
                }

                Section("Шрифт") {
                    Picker("Шрифт", selection: $readerService.selectedFont) {
                        ForEach(ReaderFont.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Цветовая схема") {
                    Picker("Тема", selection: $readerService.theme) {
                        ForEach(ReaderTheme.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Бионическое чтение") {
                    Toggle("Режим скорочтения (Bionic Reading)", isOn: $readerService.isBionicEnabled)
                        .tint(wineAccent)
                    Text("Выделяет первые буквы каждого слова полужирным начертанием, направляя взгляд и снижая утомляемость глаз.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Параметры чтения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        showingSettings = false
                    }
                    .foregroundColor(wineAccent)
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func loadBookChapters() {
        if let fileURL = EBookStorageManager.shared.fileURL(for: book.id) {
            chapters = readerService.parseBookContent(url: fileURL, bookTitle: book.title)
        } else {
            chapters = [
                ReaderChapter(
                    id: 1,
                    title: "Чтение: \(book.title)",
                    content: "Файл электронной книги пока не прикреплен к карточке этой книги.\n\nВы можете прикрепить любой файл .epub, .pdf, .fb2 или .txt через карточку книги, нажав «Прикрепить файл книги».\n\nВстроенный движок «Книжного Рая» 3.0 поддерживает Bionic Reading, литературные шрифты, кастомные темы и мгновенное сохранение цитат.",
                    estimatedReadMinutes: 1
                )
            ]
        }
    }

    private func saveQuickQuote() {
        if !chapters.isEmpty {
            let ch = chapters[currentChapterIndex]
            let sampleQuote = String(ch.content.prefix(180)) + "..."
            QuotesManager.shared.addQuote(
                text: sampleQuote,
                bookTitle: book.title,
                author: book.author,
                page: book.pagesRead > 0 ? book.pagesRead : 1,
                tags: ["Ридер 3.0"]
            )
            RPGLevelManager.shared.addXP(15, reason: "Цитата из книги")
            HapticManager.shared.success()
            showingQuoteAlert = true
        }
    }

    private func logQuickPages() {
        let newPages = min(book.totalPages, book.pagesRead + 5)
        viewModel.updateBookProgress(bookId: book.id, pagesRead: newPages)
        StreakManager.shared.recordActivity(pages: 5, minutes: 10)
        RPGLevelManager.shared.addXP(10, reason: "Чтение в ридере")
        HapticManager.shared.success()
    }
}

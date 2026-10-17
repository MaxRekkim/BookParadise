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
    @State private var selectedTexture: PaperTextureType = .sepiaComfort
    @State private var isFolioMode: Bool = true
    @State private var showingNeuroPacer: Bool = false
    @State private var showingBinauralSheet: Bool = false
    @State private var showingCircadianSheet: Bool = false
    @ObservedObject private var audioEngine = TactilePageFlipAudioEngine.shared
    @ObservedObject private var solarEngine = CircadianSolarEngine.shared

    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init(book: Book, viewModel: LibraryViewModel) {
        self.book = book
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            selectedTexture.backgroundColor
                .ignoresSafeArea()

            if !selectedTexture.isDarkMode {
                PaperNoiseOverlay()
                    .opacity(0.035)
                    .ignoresSafeArea()
            }

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
                            .foregroundColor(selectedTexture.textColor.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    let chapter = chapters[currentChapterIndex]

                    if isFolioMode {
                        let spread = FolioSpreadModel.paginateSpread(
                            chapterText: chapter.content,
                            author: book.author,
                            bookTitle: book.title,
                            chapterTitle: chapter.title,
                            currentPageBase: max(1, currentChapterIndex * 2 + 1)
                        )

                        FolioBookSpreadView(
                            spread: spread,
                            texture: selectedTexture,
                            font: readerService.selectedFont,
                            fontSize: readerService.fontSize,
                            lineSpacing: readerService.lineSpacing,
                            onPreviousPage: {
                                if currentChapterIndex > 0 {
                                    currentChapterIndex -= 1
                                    HapticManager.shared.lightTap()
                                }
                            },
                            onNextPage: {
                                if currentChapterIndex < chapters.count - 1 {
                                    currentChapterIndex += 1
                                    HapticManager.shared.lightTap()
                                }
                            }
                        )
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: readerService.lineSpacing + 10) {
                                Text(chapter.title)
                                    .font(readerService.selectedFont.font(size: readerService.fontSize + 8).bold())
                                    .foregroundColor(selectedTexture.textColor)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)

                                if readerService.isBionicEnabled {
                                    let attr = readerService.bionicAttributedString(
                                        from: chapter.content,
                                        baseFont: readerService.selectedFont.font(size: readerService.fontSize),
                                        textColor: selectedTexture.textColor
                                    )
                                    Text(attr)
                                        .lineSpacing(readerService.lineSpacing)
                                } else {
                                    Text(chapter.content)
                                        .font(readerService.selectedFont.font(size: readerService.fontSize))
                                        .foregroundColor(selectedTexture.textColor)
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
        .sheet(isPresented: $showingNeuroPacer) {
            let activeText = chapters.isEmpty ? book.title : chapters[currentChapterIndex].content
            BionicNeuroPacerView(text: activeText, bookTitle: book.title)
        }
        .sheet(isPresented: $showingBinauralSheet) {
            SoundscapeBinauralSheet()
        }
        .sheet(isPresented: $showingCircadianSheet) {
            CircadianSolarControlSheet()
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
                    .foregroundColor(selectedTexture.textColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedTexture.textColor)
                    .lineLimit(1)
                Text(book.author)
                    .font(.system(size: 11))
                    .foregroundColor(selectedTexture.textColor.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Бинауральный фокус и амбиент
            Button {
                showingBinauralSheet = true
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: "headphones")
                    .font(.system(size: 15))
                    .foregroundColor(selectedTexture.textColor)
            }

            // Нейро-пейсер RSVP скорочтение
            Button {
                showingNeuroPacer = true
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(selectedTexture.textColor)
            }

            // Циркадный астрономический спектр
            Button {
                showingCircadianSheet = true
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: solarEngine.currentPhase.icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(solarEngine.currentPhase.accentTint)
            }

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
                .background(readerService.isBionicEnabled ? wineAccent : selectedTexture.textColor.opacity(0.1))
                .foregroundColor(readerService.isBionicEnabled ? .white : selectedTexture.textColor)
                .clipShape(Capsule())
            }

            // Настройки типографики
            Button {
                showingSettings = true
                HapticManager.shared.lightTap()
            } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 16))
                    .foregroundColor(selectedTexture.textColor)
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
                    .foregroundColor(selectedTexture.textColor.opacity(0.8))

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
                Section("Текстура бумаги и OLED") {
                    Picker("Текстура", selection: $selectedTexture) {
                        ForEach(PaperTextureType.allCases) { t in
                            Text(t.title).tag(t)
                        }
                    }

                    Text(selectedTexture.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Книжная вёрстка") {
                    Toggle("Двухстраничный книжный разворот (Folio)", isOn: $isFolioMode)
                        .tint(wineAccent)
                    Text("На широких экранах iPad и Mac отображает разворот с реалистичной тенью переплёта.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Тактильная физика и шелест страниц") {
                    Toggle("Акустический шелест бумаги", isOn: $audioEngine.isSoundEnabled)
                        .tint(wineAccent)

                    Picker("Плотность бумаги", selection: $audioEngine.paperWeight) {
                        ForEach(PaperWeight.allCases) { weight in
                            Text(weight.title).tag(weight)
                        }
                    }

                    HStack {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.secondary)
                        Slider(value: Binding(
                            get: { Double(audioEngine.volume) },
                            set: { audioEngine.volume = Float($0) }
                        ), in: 0.1...1.0)
                            .tint(wineAccent)
                        Image(systemName: "speaker.wave.3")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Циркадный астрономический свет") {
                    Toggle("Авто-подстройка под солнце", isOn: $solarEngine.isAutoAstronomicalEnabled)
                        .tint(wineAccent)

                    Button(action: {
                        showingCircadianSheet = true
                    }) {
                        HStack {
                            Label(solarEngine.currentPhase.rawValue, systemImage: solarEngine.currentPhase.icon)
                                .foregroundColor(solarEngine.currentPhase.accentTint)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(solarEngine.currentPhase.kelvin)K")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

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
        .presentationDetents([.medium, .large])
    }

    private func loadBookChapters() {
        if let fileURL = EBookStorageManager.shared.fileURL(for: book.id) {
            let rawChapters = readerService.parseBookContent(url: fileURL, bookTitle: book.title)
            self.chapters = rawChapters.map {
                ReaderChapter(
                    id: $0.id,
                    title: $0.title,
                    content: SmartTypographerEngine.formatText($0.content),
                    estimatedReadMinutes: $0.estimatedReadMinutes
                )
            }
        } else {
            let sampleContent = SmartTypographerEngine.formatText("Файл электронной книги пока не прикреплен к карточке этой книги.\n\nВы можете прикрепить любой файл .epub, .pdf, .fb2 или .txt через карточку книги, нажав «Прикрепить файл книги».\n\nВстроенный движок «Книжного Рая» 3.2 поддерживает Folio двухстраничный разворот, PaperTextureKit (включая ночной OLED Midnight), Bionic Reading, RSVP Нейро-пейсер со скоростью до 800 слов в минуту, бинауральные ритмы для максимальной концентрации и автоматическую книжную типографику.")
            chapters = [
                ReaderChapter(
                    id: 1,
                    title: "Чтение: \(book.title)",
                    content: sampleContent,
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

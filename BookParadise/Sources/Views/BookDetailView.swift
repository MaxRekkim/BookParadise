import SwiftUI
import UIKit
import UniformTypeIdentifiers
import QuickLook

public struct BookDetailView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    public let bookId: Int
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var eBookStorage = EBookStorageManager.shared

    @AppStorage("kindleEmail") private var kindleEmail: String = ""
    @ObservedObject private var lendingManager = LendingManager.shared
    @ObservedObject private var noteStore = ReadingNoteStore.shared
    @State private var isShowingProgressUpdate: Bool = false
    @State private var isShowingPlanSheet: Bool = false
    @State private var isShowingQuoteScanner: Bool = false
    @State private var selectedQuoteForShare: BookQuote? = nil
    @State private var isShowingReadingSession: Bool = false
    @State private var isShowingFileImporter: Bool = false
    @State private var previewFileURL: URL? = nil
    @State private var isEditingReview: Bool = false
    @State private var reviewDraft: String = ""
    @State private var isShowingKindleAlert: Bool = false
    @State private var isShowingLendSheet: Bool = false
    @State private var isShowingNewNoteSheet: Bool = false
    @State private var selectedNoteForEdit: ReadingNote? = nil
    @State private var isShowingSpotifyCard: Bool = false

    public init(viewModel: LibraryViewModel, bookId: Int) {
        self.viewModel = viewModel
        self.bookId = bookId
    }

    private var book: Book? {
        viewModel.books.first(where: { $0.id == bookId })
    }

    public var body: some View {
        Group {
            if let book = book {
                content(for: book)
            } else {
                Text("Книга не найдена")
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for book: Book) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Верхний блок с крупной обложкой
                HStack(alignment: .top, spacing: 18) {
                    BookCoverView(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        genre: book.genre,
                        cornerRadius: 12
                    )
                    .frame(width: 125, height: 185)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.genre.rawValue)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(book.genre.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(book.genre.accentColor.opacity(0.12))
                            .cornerRadius(6)

                        Text(book.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .lineLimit(3)

                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let r = book.rating {
                            Text(r.rawValue)
                                .font(.headline)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Text(book.status.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(book.status.color)
                                .cornerRadius(8)

                            Text(book.format.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)

                // Прогресс чтения и запуск таймера
                VStack(spacing: 12) {
                    HStack {
                        Text("Прогресс чтения:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(book.pagesRead) из \(book.totalPages) стр. (\(book.displayProgressString))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }

                    ProgressView(value: Double(book.pagesRead), total: Double(max(1, book.totalPages)))
                        .tint(theme.primaryAccent)

                    if book.status != .read && book.remainingPages > 0 {
                        timeToFinishBadge(remainingPages: book.remainingPages)
                    }

                    // Большая кнопка «Сессия чтения»
                    Button(action: { isShowingReadingSession = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.headline)
                            Text("Начать сессию чтения (Секундомер)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [theme.primaryAccent, theme.secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: theme.primaryAccent.opacity(0.3), radius: 6, x: 0, y: 3)
                    }

                    HStack(spacing: 12) {
                        Button(action: { isShowingProgressUpdate = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil")
                                Text("Изменить страницы")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(theme.primaryAccent.opacity(0.12))
                            .cornerRadius(10)
                        }

                        Button(action: { isShowingPlanSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.plus")
                                Text("В план бинго")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(theme.primaryAccent.opacity(0.12))
                            .cornerRadius(10)
                        }
                    }

                    // Кнопка генерации карточки итогов в стиле Spotify
                    Button(action: { isShowingSpotifyCard = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.subheadline)
                            Text("Поделиться карточкой (Spotify Style)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(theme.primaryAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(theme.primaryAccent.opacity(0.12))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)

                // Электронная книга / Файл книги (PDF, EPUB)
                eBookSection(for: book)

                // Цитаты и заметки из книги (OCR / Apple Vision)
                quotesSection(for: book)

                // Мой отзыв и рецензия
                reviewSection(for: book)

                // Серия / Цикл (если есть)
                if book.hasCycle {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "bookmark.circle.fill")
                                .foregroundColor(theme.primaryAccent)
                            Text("Серия: \(book.cycleName)")
                                .font(.headline)
                            Spacer()
                            Text("№ \(book.cycleNumber)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }

                        if let percent = book.cycleStatus {
                            HStack {
                                Text("Прогресс серии:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.1f%%", percent))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.primaryAccent)
                            }
                            ProgressView(value: percent, total: 100.0)
                                .tint(theme.primaryAccent)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }

                // Детальные данные книги (Паспорт книги)
                VStack(spacing: 12) {
                    detailRow(title: "Номер в каталоге", value: "#\(book.id)")
                    Divider()
                    detailRow(title: "Издание и серия", value: book.edition.isEmpty ? "—" : book.edition)
                    Divider()
                    detailRow(title: "ISBN", value: book.isbn.isEmpty ? "—" : book.isbn)
                    Divider()
                    detailRow(title: "Полка хранения", value: book.shelf.rawValue)
                    Divider()
                    detailRow(title: "План чтения", value: book.planMonth ?? "—")
                    Divider()
                    detailRow(title: "Начало чтения", value: book.startDate ?? "—")
                    Divider()
                    detailRow(title: "Завершено", value: book.endDate ?? "—")
                    Divider()
                    detailRow(title: "Дата покупки", value: book.purchaseDate ?? "—")
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)

                // Заметки и конспекты Markdown
                notesSection(for: book)

                // Экспорт в Markdown для Obsidian / Notion
                exportSection(for: book)

                Spacer(minLength: 30)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(book.title)
        .sheet(isPresented: $isShowingLendSheet) {
            LendBookSheet(book: book)
        }
        .sheet(isPresented: $isShowingProgressUpdate) {
            ProgressUpdateSheet(viewModel: viewModel, book: book)
        }
        .sheet(isPresented: $isShowingPlanSheet) {
            AddToPlanSheet(viewModel: viewModel, book: book)
        }
        .sheet(isPresented: $isShowingQuoteScanner) {
            QuoteScannerView(book: book)
        }
        .sheet(item: $selectedQuoteForShare) { q in
            QuoteCardShareView(quote: q, book: book, onDismiss: {
                selectedQuoteForShare = nil
            })
        }
        .sheet(isPresented: $isShowingReadingSession) {
            ReadingSessionView(viewModel: viewModel, book: book)
        }
        .sheet(isPresented: $isShowingNewNoteSheet) {
            MarkdownEditorView(viewModel: viewModel, initialBookId: book.id)
        }
        .sheet(item: $selectedNoteForEdit) { note in
            MarkdownEditorView(viewModel: viewModel, note: note, initialBookId: book.id)
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.pdf, .plainText, UTType(filenameExtension: "epub") ?? .data, UTType(filenameExtension: "fb2") ?? .data]
        ) { result in
            switch result {
            case .success(let url):
                eBookStorage.saveBookFile(bookId: book.id, from: url)
            case .failure(let error):
                print("File import failed: \(error)")
            }
        }
        .quickLookPreview($previewFileURL)
        .sheet(isPresented: $isEditingReview) {
            NavigationStack {
                Form {
                    Section(header: Text("Отзыв и впечатления о книге")) {
                        TextEditor(text: $reviewDraft)
                            .frame(minHeight: 180)
                    }
                }
                .navigationTitle("Мой отзыв")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { isEditingReview = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Сохранить") {
                            viewModel.updateReview(bookId: book.id, review: reviewDraft)
                            isEditingReview = false
                        }
                        .fontWeight(.bold)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingSpotifyCard) {
            BookSpotifyShareCardView(book: book)
                .macSheetFrame()
        }
    }

    // MARK: - Секция Заметок Markdown
    private func notesSection(for book: Book) -> some View {
        let bookNotes = noteStore.notesForBook(bookId: book.id)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(theme.primaryAccent)
                Text("Заметки и конспекты Markdown")
                    .font(.headline)
                if !bookNotes.isEmpty {
                    Text("(\(bookNotes.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    isShowingNewNoteSheet = true
                }) {
                    Label("Добавить", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                }
            }

            if bookNotes.isEmpty {
                Text("У вас пока нет заметок по этой книге. Создайте конспект, мысли по главам или цитатник в Markdown редакторе.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(bookNotes) { note in
                        Button(action: {
                            selectedNoteForEdit = note
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(note.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        if note.isPinned {
                                            Image(systemName: "pin.fill")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    Text(note.excerpt)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Секция Отзыва и Рецензии
    private func reviewSection(for book: Book) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(theme.primaryAccent)
                Text("Мой отзыв и заметки")
                    .font(.headline)
                Spacer()
                Button(action: {
                    reviewDraft = book.review ?? ""
                    isEditingReview = true
                }) {
                    Text(book.review == nil ? "+ Написать отзыв" : "Изменить")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                }
            }

            if let rev = book.review, !rev.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(rev)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor.label))
                    .padding(.top, 2)
            } else {
                Text("Напишите свои впечатления, мысли и оценку после прочтения...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Секция Электронной книги / Файла (PDF / EPUB)
    private func eBookSection(for book: Book) -> some View {
        let hasFile = eBookStorage.hasFile(for: book.id)
        let fileName = eBookStorage.fileDisplayName(for: book.id)
        let fileSize = eBookStorage.fileSizeFormatted(for: book.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(theme.primaryAccent)
                Text("Файл книги (PDF / EPUB)")
                    .font(.headline)
                Spacer()
                if hasFile {
                    Text(fileSize ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if hasFile, let name = fileName {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: name.hasSuffix(".epub") ? "book.closed.fill" : "doc.fill")
                            .font(.title2)
                            .foregroundColor(theme.primaryAccent)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text("Файл сохранён в памяти приложения")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(theme.primaryAccent.opacity(0.06))
                    .cornerRadius(10)

                    HStack(spacing: 8) {
                        Button(action: {
                            if let url = eBookStorage.fileURL(for: book.id) {
                                previewFileURL = url
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                Text("Читать")
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(theme.primaryAccent)
                            .cornerRadius(10)
                        }

                        if let fileURL = eBookStorage.fileURL(for: book.id) {
                            ShareLink(
                                item: fileURL,
                                subject: Text(book.title),
                                message: Text("Книга «\(book.title)» для отправки на Kindle: \(kindleEmail)")
                            ) {
                                HStack(spacing: 4) {
                                    Image(systemName: "paperplane.fill")
                                    Text("На Kindle")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.primaryAccent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(theme.primaryAccent.opacity(0.12))
                                .cornerRadius(10)
                            }
                        }

                        Button(role: .destructive, action: {
                            eBookStorage.removeBookFile(bookId: book.id)
                        }) {
                            Image(systemName: "trash")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(10)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text("Электронный файл книги не прикреплен")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: { isShowingFileImporter = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Прикрепить PDF / EPUB")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(theme.primaryAccent.opacity(0.12))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Секция Цитат и заметок
    private func quotesSection(for book: Book) -> some View {
        let bookQuotes = quotesManager.quotes(for: book.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(theme.primaryAccent)
                Text("Цитаты и заметки (\(bookQuotes.count))")
                    .font(.headline)
                Spacer()
                Button(action: { isShowingQuoteScanner = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                        Text("Добавить")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.primaryAccent)
                    .cornerRadius(8)
                }
            }

            if bookQuotes.isEmpty {
                VStack(spacing: 8) {
                    Text("Цитат пока нет")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Нажмите «Добавить», чтобы сфотографировать страницу книги и распознать текст через камеру или записать вручную.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 10) {
                    ForEach(bookQuotes) { q in
                        Button(action: { selectedQuoteForShare = q }) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    if let page = q.pageNumber, page > 0 {
                                        Text("Стр. \(page)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(theme.primaryAccent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(theme.primaryAccent.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Text("«\(q.text)»")
                                    .font(.system(.subheadline, design: .serif))
                                    .italic()
                                    .lineLimit(3)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)

                                if let note = q.note, !note.isEmpty {
                                    Text("Заметка: \(note)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Трекер одолженных книг
    private func lendingSection(for book: Book) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(theme.primaryAccent)
                Text("Книга у друзей (Трекер долгов)")
                    .font(.headline)
                Spacer()
            }

            if let active = lendingManager.activeLending(for: String(book.id)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(active.type == .lentToFriend ? "Одолжена другу:" : "Взята у:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(active.personName)
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        if let days = active.daysRemaining {
                            if days < 0 {
                                Text("Просрочено \(abs(days)) дн.")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.15))
                                    .foregroundColor(.red)
                                    .clipShape(Capsule())
                            } else {
                                Text("Осталось \(days) дн.")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if let contact = active.contact, !contact.isEmpty {
                        Text("Контакт: \(contact)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Button(action: {
                        withAnimation {
                            lendingManager.markReturned(recordId: active.id)
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Отметить возврат книги")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(12)
            } else {
                Button(action: { isShowingLendSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.circle")
                        Text("Одолжить книгу другу / Записать в долг")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.primaryAccent.opacity(0.12))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Экспорт в Markdown
    private func exportSection(for book: Book) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(theme.primaryAccent)
                Text("Экспорт для заметок (Obsidian / Notion)")
                    .font(.headline)
                Spacer()
            }

            Text("Создаёт готовый файл Markdown с YAML Frontmatter, оценкой, рецензией и всеми сохраненными цитатами книги.")
                .font(.caption)
                .foregroundColor(.secondary)

            if let exportFile = generateMarkdownFile(for: book) {
                ShareLink(item: exportFile, preview: SharePreview("\(book.title).md", image: Image(systemName: "doc.text"))) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Поделиться Markdown (.md)")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.primaryAccent)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func generateMarkdownFile(for book: Book) -> URL? {
        let md = MarkdownExportService.shared.exportBookToMarkdown(book: book, quotes: quotesManager.quotes)
        return MarkdownExportService.shared.createTemporaryMarkdownFile(content: md, filename: "\(book.title)")
    }

    private func timeToFinishBadge(remainingPages: Int) -> some View {
        let estimate = ReadingSessionManager.shared.estimatedTimeToFinish(remainingPages: remainingPages)
        return HStack(spacing: 6) {
            Image(systemName: "hourglass")
                .font(.caption)
                .foregroundColor(.orange)
            Text("До финала: \(estimate.displayString)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

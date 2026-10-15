import SwiftUI
import UIKit

public struct AddBookSheet: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Основные 4 поля + сканер
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var totalPagesText: String = ""
    @State private var selectedGenre: Genre = .modernProse
    @State private var coverURL: String = ""
    @State private var isbn: String = ""
    
    // Свернутый блок «Дополнительно»
    @State private var isAdditionalExpanded: Bool = false
    @State private var format: BookFormat = .paper
    @State private var selectedEdition: String = "Эксклюзивная классика"
    @State private var cycleName: String = "-"
    @State private var cycleNumber: String = "-"
    @State private var isPurchasedToday: Bool = true
    @State private var customPurchaseDate: Date = Date()
    @State private var selectedPlanMonth: String = ""
    
    // Сканер штрихкодов камеры
    @State private var isShowingScanner: Bool = false
    @State private var isLookingUpISBN: Bool = false
    
    // Подсказки авторов
    @State private var isAuthorAutocompleteVisible: Bool = false
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    private var authorSuggestions: [String] {
        return viewModel.filterAuthors(matching: author)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Блок сканирования ISBN
                Section {
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title3)
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Сканировать ISBN камерой")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(isbn.isEmpty ? "Наведите на штрихкод книги" : "ISBN: \(isbn)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isLookingUpISBN {
                                HStack(spacing: 8) {
                                    ThinkingOrbView(state: .searching, size: 28, speedMultiplier: 1.2)
                                    Text("Поиск...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Основные 4 поля ввода
                Section(header: Text("Основная информация")) {
                    TextField("Название книги *", text: $title)
                    
                    // Автор с автодополнением
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Автор *", text: $author)
                            .onChange(of: author) { newValue in
                                isAuthorAutocompleteVisible = !newValue.isEmpty
                            }
                        
                        if isAuthorAutocompleteVisible && !authorSuggestions.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(authorSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            author = suggestion
                                            isAuthorAutocompleteVisible = false
                                        }) {
                                            Text(suggestion)
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.orange.opacity(0.15))
                                                .foregroundColor(.orange)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    TextField("Всего страниц *", text: $totalPagesText)
                        .keyboardType(.numberPad)
                }
                
                // Выбор жанра (9 кнопок-категорий)
                Section(header: Text("Жанр (9 фиксированных категорий)")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                        ForEach(Genre.allCases) { g in
                            Button(action: {
                                selectedGenre = g
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: g.iconName)
                                        .font(.caption)
                                    Text(g.rawValue)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedGenre == g ? g.accentColor : Color(UIColor.tertiarySystemFill))
                                .foregroundColor(selectedGenre == g ? .white : .primary)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Ссылка на обложку с предпросмотром
                Section(header: Text("Обложка книги")) {
                    HStack {
                        TextField("URL ссылки на обложку", text: $coverURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        Button(action: pasteFromClipboard) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if let url = URL(string: coverURL.trimmingCharacters(in: .whitespacesAndNewlines)), !coverURL.isEmpty {
                        HStack {
                            Spacer()
                            BookCoverView(
                                coverURL: url,
                                title: title.isEmpty ? "Предпросмотр" : title,
                                author: author,
                                genre: selectedGenre,
                                cornerRadius: 8
                            )
                            .frame(width: 80, height: 120)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Свернутый блок «Дополнительно»
                Section {
                    DisclosureGroup(isExpanded: $isAdditionalExpanded) {
                        // Формат книги
                        Picker("Формат книги", selection: $format) {
                            ForEach(BookFormat.allCases) { f in
                                Label(f.rawValue, systemImage: f.iconName).tag(f)
                            }
                        }
                        
                        // Издание
                        Picker("Издание / Серия", selection: $selectedEdition) {
                            ForEach(viewModel.availableEditions, id: \.self) { ed in
                                Text(ed).tag(ed)
                            }
                        }
                        
                        // Цикл и номер
                        TextField("Название цикла (по умолч. -)", text: $cycleName)
                        TextField("Номер в цикле (1, 2, 3...)", text: $cycleNumber)
                        
                        // Дата покупки
                        Toggle("Куплена сегодня", isOn: $isPurchasedToday)
                        if !isPurchasedToday {
                            DatePicker("Дата покупки", selection: $customPurchaseDate, displayedComponents: .date)
                        }
                        
                        // План чтения
                        Picker("В план чтения", selection: $selectedPlanMonth) {
                            Text("Без плана").tag("")
                            ForEach(viewModel.availableBingoMonths, id: \.self) { m in
                                Text(m).tag(m)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.secondary)
                            Text("Дополнительные параметры")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("Новая книга")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") { saveBook() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Int(totalPagesText) == nil)
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                NavigationStack {
                    BarcodeScannerView(scannedCode: $isbn) { scanned in
                        handleScannedISBN(scanned)
                    }
                    .navigationTitle("Сканирование ISBN")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Закрыть") { isShowingScanner = false }
                        }
                    }
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let clipboardString = UIPasteboard.general.string {
            coverURL = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func handleScannedISBN(_ code: String) {
        isbn = code
        isLookingUpISBN = true
        
        Task {
            if let info = await GoogleBooksLookupService.shared.lookupISBN(code) {
                await MainActor.run {
                    if let t = info.title, !t.isEmpty { self.title = t }
                    if let a = info.author, !a.isEmpty { self.author = a }
                    if let p = info.pageCount, p > 0 { self.totalPagesText = "\(p)" }
                    if let c = info.thumbnailURL, !c.isEmpty { self.coverURL = c }
                    if let pub = info.publisher, !pub.isEmpty { self.selectedEdition = pub }
                    self.isLookingUpISBN = false
                }
            } else {
                await MainActor.run { self.isLookingUpISBN = false }
            }
        }
    }
    
    private func saveBook() {
        guard let total = Int(totalPagesText), total > 0 else { return }
        
        let purchaseDateStr: String?
        if isPurchasedToday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            purchaseDateStr = formatter.string(from: Date())
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            purchaseDateStr = formatter.string(from: customPurchaseDate)
        }
        
        viewModel.addNewBook(
            title: title,
            author: author,
            totalPages: total,
            genre: selectedGenre,
            edition: selectedEdition,
            isbn: isbn,
            cycleName: cycleName,
            cycleNumber: cycleNumber,
            coverURL: coverURL,
            format: format,
            planMonth: selectedPlanMonth.isEmpty ? nil : selectedPlanMonth,
            purchaseDate: purchaseDateStr
        )
        
        dismiss()
    }
}

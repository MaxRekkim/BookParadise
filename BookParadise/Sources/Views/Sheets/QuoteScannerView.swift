import SwiftUI
import AVFoundation
import Vision
#if canImport(VisionKit)
import VisionKit
#endif

public struct QuoteScannerView: View {
    public let book: Book
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var quoteText: String = ""
    @State private var pageNumberText: String = ""
    @State private var personalNote: String = ""
    @State private var isShowingCameraPicker: Bool = false
    @State private var isProcessingOCR: Bool = false
    @State private var recognizedFragments: [String] = []

    public init(book: Book) {
        self.book = book
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Блок сканирования камерой
                Section(header: Text("Распознавание со страницы")) {
                    Button(action: { isShowingCameraPicker = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "text.viewfinder")
                                .font(.title2)
                                .foregroundColor(theme.primaryAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Сфотографировать страницу книги")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text("Apple Vision распознает текст на русском и английском")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if isProcessingOCR {
                                ProgressView()
                            } else {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if !recognizedFragments.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Нажмите на абзац, чтобы вставить:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(recognizedFragments, id: \.self) { fragment in
                                Button(action: {
                                    if quoteText.isEmpty {
                                        quoteText = fragment
                                    } else {
                                        quoteText += "\n" + fragment
                                    }
                                }) {
                                    Text(fragment)
                                        .font(.caption)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(theme.primaryAccent.opacity(0.08))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Текст цитаты
                Section(header: Text("Текст цитаты *")) {
                    TextEditor(text: $quoteText)
                        .frame(minHeight: 120)
                }

                // Параметры цитаты
                Section(header: Text("Детали")) {
                    HStack {
                        Text("Номер страницы:")
                        Spacer()
                        TextField("например, 42", text: $pageNumberText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    TextField("Личная мысль / Заметка к цитате", text: $personalNote)
                }

                // Предпросмотр цитаты
                if !quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section(header: Text("Предпросмотр карточки")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .foregroundColor(theme.primaryAccent)
                                Spacer()
                                if let p = Int(pageNumberText), p > 0 {
                                    Text("стр. \(p)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text(quoteText)
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundColor(.primary)

                            HStack {
                                Spacer()
                                Text("— \(book.author), «\(book.title)»")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }

                            if !personalNote.isEmpty {
                                Divider()
                                HStack {
                                    Image(systemName: "note.text")
                                        .font(.caption)
                                        .foregroundColor(theme.primaryAccent)
                                    Text(personalNote)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(theme.paperBackground)
                        .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Новая цитата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { saveQuote() }
                        .disabled(quoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $isShowingCameraPicker) {
                PhotoTextCaptureSheet { image in
                    performOCR(on: image)
                }
            }
        }
    }

    private func saveQuote() {
        let pageNum = Int(pageNumberText)
        quotesManager.addQuote(
            bookId: book.id,
            text: quoteText,
            pageNumber: pageNum,
            note: personalNote.isEmpty ? nil : personalNote
        )
        dismiss()
    }

    private func performOCR(on image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        isProcessingOCR = true
        recognizedFragments.removeAll()

        Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["ru-RU", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])

            guard let results = request.results else {
                await MainActor.run {
                    self.isProcessingOCR = false
                }
                return
            }

            var textPieces: [String] = []
            for observation in results {
                if let candidate = observation.topCandidates(1).first {
                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if text.count > 10 {
                        textPieces.append(text)
                    }
                }
            }

            let finalPieces = textPieces
            await MainActor.run {
                self.recognizedFragments = Array(finalPieces.prefix(8))
                if self.quoteText.isEmpty && !finalPieces.isEmpty {
                    self.quoteText = finalPieces.joined(separator: " ")
                }
                self.isProcessingOCR = false
            }
        }
    }
}

// UIImagePickerController для захвата фото страницы
struct PhotoTextCaptureSheet: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        #if targetEnvironment(macCatalyst)
        picker.sourceType = .photoLibrary
        #else
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        #endif
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoTextCaptureSheet
        init(_ parent: PhotoTextCaptureSheet) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

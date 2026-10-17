import SwiftUI
import UIKit

public struct ProgressUpdateSheet: View {
    @ObservedObject public var viewModel: LibraryViewModel
    public let book: Book
    @Environment(\.dismiss) private var dismiss
    
    public var onDismiss: (() -> Void)? = nil
    
    @State private var pagesRead: Int
    @State private var selectedRating: BookRating?
    
    public init(viewModel: LibraryViewModel, book: Book, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.book = book
        self.onDismiss = onDismiss
        _pagesRead = State(initialValue: book.pagesRead)
        _selectedRating = State(initialValue: book.rating)
    }
    
    private func handleDismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
        #if canImport(UIKit)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .dismiss(animated: true, completion: nil)
        #endif
    }
    
    private var isFinished: Bool {
        return pagesRead >= book.totalPages
    }
    
    private var progressPercent: Double {
        guard book.totalPages > 0 else { return 0 }
        return min(100.0, (Double(pagesRead) / Double(book.totalPages)) * 100.0)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Карточка книги
                HStack(spacing: 14) {
                    BookCoverView(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        genre: book.genre,
                        cornerRadius: 8
                    )
                    .frame(width: 60, height: 90)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack {
                            Text("Всего: \(book.totalPages) стр.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f%%", progressPercent))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Главный блок ввода страниц
                VStack(spacing: 16) {
                    HStack {
                        Text("Прочитано страниц:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        TextField("0", value: $pagesRead, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .frame(width: 100)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(8)
                    }
                    
                    // Ползунок
                    Slider(
                        value: Binding(
                            get: { Double(pagesRead) },
                            set: { pagesRead = Int($0) }
                        ),
                        in: 0...Double(book.totalPages),
                        step: 1
                    )
                    .tint(.orange)
                    
                    // Кнопка быстрого закрытия «Прочитана полностью»
                    Button(action: {
                        pagesRead = book.totalPages
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Прочитана полностью (\(book.totalPages) стр.)")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isFinished ? .green : .accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Если книга прочитана — показываем выбор оценки (6 кнопок из ТЗ)
                if isFinished {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Поставьте оценку книге:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 6) {
                            ForEach(BookRating.allCases) { r in
                                Button(action: {
                                    selectedRating = r
                                }) {
                                    Text(r.rawValue)
                                        .font(.system(size: r == .masterpiece ? 12 : 14, weight: .bold))
                                        .foregroundColor(selectedRating == r ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedRating == r ? Color.orange : Color(UIColor.tertiarySystemFill))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Spacer()
                
                // Кнопка сохранения
                Button(action: saveProgress) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Сохранить и синхронизировать")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.bottom, 8)
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Прогресс чтения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { handleDismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { saveProgress() }
                        .fontWeight(.bold)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .onExitCommand {
                handleDismiss()
            }
            .interactiveDismissDisabled(false)
        }
    }
    
    private func saveProgress() {
        viewModel.updateProgress(for: book, newPages: pagesRead, rating: selectedRating)
        handleDismiss()
    }
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct MarginaliaEditorSheet: View {
    public let bookId: Int
    public let pageNumber: Int
    public let yOffsetFraction: Double
    
    @ObservedObject private var marginalia = MarginaliaManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var noteText: String = ""
    @State private var selectedSymbol: MarginaliaSymbol = .manicule
    @State private var selectedWash: WatercolorWashColor = .honeyAmber
    @State private var selectedStyle: HandwritingStyle = .scholarCursive
    
    public init(bookId: Int, pageNumber: Int, yOffsetFraction: Double = 0.3) {
        self.bookId = bookId
        self.pageNumber = pageNumber
        self.yOffsetFraction = yOffsetFraction
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Section 1: Note Text
                Section("Заметка на полях (страница \(pageNumber))") {
                    TextField("Ваша мысль, толкование или цитата...", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.system(.body, design: selectedStyle.fontDesign))
                }
                
                // Section 2: Scholarly Symbol
                Section("Символ маргиналии") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MarginaliaSymbol.allCases) { sym in
                                Button(action: {
                                    selectedSymbol = sym
                                    HapticManager.shared.lightTap()
                                }) {
                                    VStack(spacing: 4) {
                                        Text(sym.rawValue)
                                            .font(.title2)
                                            .foregroundColor(selectedSymbol == sym ? .white : theme.primaryAccent)
                                        Text(sym.rawValue == "☞" ? "Manicule" : sym.rawValue)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(selectedSymbol == sym ? .white : .secondary)
                                    }
                                    .frame(width: 54, height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(selectedSymbol == sym ? theme.primaryAccent : Color(UIColor.tertiarySystemGroupedBackground))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Section 3: Watercolor Wash Pigment
                Section("Акварельный пигмент выделителя") {
                    HStack(spacing: 14) {
                        ForEach(WatercolorWashColor.allCases) { wash in
                            Button(action: {
                                selectedWash = wash
                                HapticManager.shared.lightTap()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(wash.color)
                                        .frame(width: 36, height: 36)
                                        .shadow(color: wash.color.opacity(0.4), radius: 4, x: 0, y: 2)
                                    
                                    if selectedWash == wash {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Section 4: Handwriting Style
                Section("Стиль почерка") {
                    Picker("Стиль", selection: $selectedStyle) {
                        ForEach(HandwritingStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Новая маргиналия")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveMarginalia()
                    }
                    .fontWeight(.bold)
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveMarginalia() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newNote = MarginaliaNote(
            bookId: bookId,
            pageNumber: pageNumber,
            yOffsetFraction: yOffsetFraction,
            text: trimmed,
            symbol: selectedSymbol,
            washColor: selectedWash,
            handwritingStyle: selectedStyle
        )
        
        marginalia.addNote(newNote)
        dismiss()
    }
}

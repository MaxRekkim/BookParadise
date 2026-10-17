import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct MarginaliaJournalListView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var marginalia = MarginaliaManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var filterSymbol: MarginaliaSymbol? = nil
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var filteredNotes: [MarginaliaNote] {
        if let sym = filterSymbol {
            return marginalia.notes.filter { $0.symbol == sym }
        }
        return marginalia.notes
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Summary Banner
            marginaliaSummaryHeader
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
            
            // Symbol Filter Chips
            symbolFilterChips
                .padding(.bottom, 8)
            
            Divider()
            
            // Notes List or Empty State
            if filteredNotes.isEmpty {
                emptyMarginaliaState
            } else {
                List {
                    ForEach(filteredNotes) { note in
                        marginaliaRow(note: note)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let note = filteredNotes[index]
                            marginalia.removeNote(id: note.id)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Header
    private var marginaliaSummaryHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.primaryAccent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("☞")
                    .font(.title2)
                    .foregroundColor(theme.primaryAccent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Маргиналии и заметки на полях")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                
                Text("\(marginalia.totalNotesCount()) заметок • \(marginalia.totalDogEarsCount()) загнутых уголков")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Symbol Filter Chips
    private var symbolFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "Все", isSelected: filterSymbol == nil) {
                    filterSymbol = nil
                }
                
                ForEach(MarginaliaSymbol.allCases) { sym in
                    filterChip(title: "\(sym.rawValue) \(sym.title)", isSelected: filterSymbol == sym) {
                        filterSymbol = sym
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticManager.shared.lightTap()
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color(UIColor.label))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? theme.primaryAccent : Color(UIColor.secondarySystemGroupedBackground))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Row
    private func marginaliaRow(note: MarginaliaNote) -> some View {
        let matchingBook = viewModel.books.first { $0.id == note.bookId }
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill((note.washColor?.color ?? theme.primaryAccent).opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text(note.symbol.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(note.washColor?.color ?? theme.primaryAccent)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(matchingBook?.title ?? "Книга из библиотеки")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(1)
                    
                    Text("Страница \(note.pageNumber)")
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                Text(note.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            Text(note.text)
                .font(.system(size: 13, weight: .regular, design: note.handwritingStyle.fontDesign))
                .italic()
                .foregroundColor(Color(UIColor.label))
                .lineSpacing(3)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Empty State
    private var emptyMarginaliaState: some View {
        VStack(spacing: 14) {
            Spacer()
            
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 44))
                .foregroundColor(theme.primaryAccent.opacity(0.6))
            
            Text("Поля ваших книг пока чисты")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.label))
            
            Text("Ведите диалог с автором на полях: используйте перст-указатель ☞, делайте пометки и загибайте уголки важных страниц в ридере.")
                .font(.subheadline)
                .foregroundColor(Color(UIColor.secondaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(3)
            
            Spacer()
        }
    }
}

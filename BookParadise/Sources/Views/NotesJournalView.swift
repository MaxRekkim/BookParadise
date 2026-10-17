import SwiftUI

public struct NotesJournalView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var noteStore = ReadingNoteStore.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    @Environment(\.dismiss) private var dismiss
    public var onDismiss: (() -> Void)? = nil
    
    @State private var searchText: String = ""
    @State private var selectedTag: String? = nil
    @State private var selectedNoteForEditing: ReadingNote? = nil
    @State private var showingNewNoteSheet: Bool = false
    
    public init(viewModel: LibraryViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
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
    
    private var allTags: [String] {
        var tagsSet = Set<String>()
        for n in noteStore.notes {
            for t in n.tags {
                tagsSet.insert(t)
            }
        }
        return Array(tagsSet).sorted()
    }
    
    private var filteredNotes: [ReadingNote] {
        var result = noteStore.searchNotes(query: searchText)
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        return result
    }
    
    private var pinnedNotes: [ReadingNote] {
        filteredNotes.filter { $0.isPinned }
    }
    
    private var regularNotes: [ReadingNote] {
        filteredNotes.filter { !$0.isPinned }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Строка поиска (зафиксирована вверху, не съезжает)
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Поиск по заметкам, идеям и цитатам...", text: $searchText)
                        .font(.subheadline)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                // Фильтр по тегам
                if !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            tagPill(title: "Все", isSelected: selectedTag == nil) {
                                selectedTag = nil
                            }
                            ForEach(allTags, id: \.self) { tag in
                                tagPill(title: "#\(tag)", isSelected: selectedTag == tag) {
                                    if selectedTag == tag {
                                        selectedTag = nil
                                    } else {
                                        selectedTag = tag
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                
                // Список заметок
                if filteredNotes.isEmpty {
                    emptyStateView
                } else {
                    List {
                        // Закрепленные заметки
                        if !pinnedNotes.isEmpty {
                            Section(header: Label("Закрепленные", systemImage: "pin.fill")) {
                                ForEach(pinnedNotes) { n in
                                    noteCardRow(for: n)
                                }
                            }
                        }
                        
                        // Все заметки
                        Section(header: Text("Все записи (\(regularNotes.count))")) {
                            ForEach(regularNotes) { n in
                                noteCardRow(for: n)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Дневник заметок (Studio)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: handleDismiss) {
                        Text("Готово")
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryAccent)
                    }
                    .keyboardShortcut(.cancelAction)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewNoteSheet = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.primaryAccent)
                    }
                }
            }
            .onMacExitCommand {
                handleDismiss()
            }
            .interactiveDismissDisabled(false)
            .sheet(isPresented: $showingNewNoteSheet) {
                MarkdownEditorView(viewModel: viewModel)
            }
            .sheet(item: $selectedNoteForEditing) { note in
                MarkdownEditorView(viewModel: viewModel, note: note)
            }
        }
    }
    
    private func tagPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2)
                .fontWeight(isSelected ? .bold : .medium)
                .foregroundColor(isSelected ? .white : Color(UIColor.label))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? theme.primaryAccent : Color(UIColor.tertiarySystemFill))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func noteCardRow(for n: ReadingNote) -> some View {
        Button(action: {
            selectedNoteForEditing = n
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(n.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor.label))
                            .lineLimit(1)
                        
                        if let bTitle = n.bookTitle {
                            HStack(spacing: 4) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 9))
                                Text(bTitle)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(theme.primaryAccent)
                        }
                    }
                    
                    Spacer()
                    
                    if n.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Text(n.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Фрагмент текста
                Text(n.excerpt)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Нижняя строка: теги и статистика
                HStack(spacing: 6) {
                    ForEach(n.tags.prefix(3), id: \.self) { t in
                        Text("#\(t)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(UIColor.tertiarySystemFill))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    Text("\(n.wordCount) сл. • \(n.readingTimeMinutes) мин")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                noteStore.deleteNote(id: n.id)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
            
            Button {
                noteStore.togglePin(id: n.id)
            } label: {
                Label(n.isPinned ? "Открепить" : "Закрепить", systemImage: n.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "note.text")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("Заметок пока нет")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("Создавайте красивые Markdown конспекты, рецензии, фиксируйте главные цитаты и выписывайте инсайты из книг.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingNewNoteSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Создать первую заметку")
                }
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(theme.primaryAccent)
                .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
}

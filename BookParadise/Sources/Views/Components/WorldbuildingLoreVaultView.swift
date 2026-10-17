import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct WorldbuildingLoreVaultView: View {
    @State public var vault: BookLoreVault
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedCategory: LoreEntryCategory? = nil
    @State private var expandedEntryId: UUID? = nil
    
    public init(vault: BookLoreVault = .sampleMasterAndMargaritaVault) {
        _vault = State(initialValue: vault)
    }
    
    private var filteredEntries: [LoreEntry] {
        if let cat = selectedCategory {
            return vault.entries.filter { $0.category == cat }
        }
        return vault.entries
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Chapter Progress Bar / Stepper
            chapterProgressSection
            
            // Category Filter Pills
            categoryFilterChips
            
            // Lore Entries List
            VStack(spacing: 12) {
                ForEach(filteredEntries) { entry in
                    loreEntryCard(entry: entry)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("КОДЕКС ВСЕЛЕННОЙ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("\(vault.unlockedEntriesCount)/\(vault.entries.count) ОТКРЫТО")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.teal))
                }
                
                Text(vault.bookTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "books.vertical.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Chapter Progress Stepper
    private var chapterProgressSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Текущая глава чтения")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text("Глава \(vault.currentReaderChapter)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if vault.currentReaderChapter > 1 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vault.currentReaderChapter -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(vault.currentReaderChapter > 1 ? theme.primaryAccent : Color(UIColor.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(vault.currentReaderChapter <= 1)
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    vault.currentReaderChapter += 1
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.primaryAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
        )
    }
    
    // MARK: - Category Filters
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                catChip(title: "Все", isSelected: selectedCategory == nil) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    selectedCategory = nil
                }
                
                ForEach(LoreEntryCategory.allCases, id: \.self) { cat in
                    catChip(
                        title: cat.rawValue,
                        icon: cat.iconName,
                        isSelected: selectedCategory == cat
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedCategory = (selectedCategory == cat) ? nil : cat
                    }
                }
            }
        }
    }
    
    private func catChip(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? theme.primaryAccent : Color(UIColor.tertiarySystemGroupedBackground))
            )
            .foregroundColor(isSelected ? .white : Color(UIColor.secondaryLabel))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Lore Entry Card
    private func loreEntryCard(entry: LoreEntry) -> some View {
        let lock = entry.lockStatus(atCurrentChapter: vault.currentReaderChapter)
        let isExpanded = expandedEntryId == entry.id
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: entry.category.iconName)
                    .font(.caption2)
                    .foregroundColor(entry.category.accentColor)
                
                Text(entry.category.rawValue)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(entry.category.accentColor)
                
                Spacer()
                
                switch lock {
                case .safe:
                    HStack(spacing: 3) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 8))
                        Text("Безопасно")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.1)))
                case .locked(let safeAtChapter):
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("Гл. \(safeAtChapter)+")
                            .font(.system(size: 9, weight: .heavy))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
                }
            }
            
            Text(entry.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.label))
            
            switch lock {
            case .safe:
                // Safe Brief
                Text(entry.briefSummary)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                
                // Deep lore on expansion
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        Divider()
                        
                        Text("ГЛУБОКИЙ ЛОР")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(theme.primaryAccent)
                        
                        Text(entry.deepLore)
                            .font(.caption)
                            .foregroundColor(Color(UIColor.label))
                            .lineSpacing(2)
                        
                        if !entry.relatedCharacters.isEmpty {
                            HStack(spacing: 4) {
                                Text("Связи:")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color(UIColor.tertiaryLabel))
                                ForEach(entry.relatedCharacters, id: \.self) { character in
                                    Text(character)
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.top, 4)
                }
            case .locked(let safeAtChapter):
                // Locked teaser with unlock button
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.orange)
                        Text("Спойлер: открывается в главе \(safeAtChapter)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let index = vault.entries.firstIndex(where: { $0.id == entry.id }) {
                            vault.entries[index].isManuallyUnlocked = true
                        }
                    }) {
                        Text("Показать всё равно")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.orange))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.orange.opacity(0.06))
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.7))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if lock == .safe {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if expandedEntryId == entry.id {
                        expandedEntryId = nil
                    } else {
                        expandedEntryId = entry.id
                    }
                }
            }
        }
    }
}

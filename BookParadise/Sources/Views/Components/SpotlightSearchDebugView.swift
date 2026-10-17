import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct SpotlightSearchDebugView: View {
    @ObservedObject public var indexer = CoreSpotlightIndexer.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var sampleCatalog: [SpotlightBookMetadata] = CoreSpotlightIndexer.sampleIndexCatalog
    @State private var searchQuery: String = ""
    @State private var isReindexing: Bool = false
    
    public init() {}
    
    private var searchResults: [SpotlightBookMetadata] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return sampleCatalog
        }
        let q = searchQuery.lowercased()
        return sampleCatalog.filter {
            $0.title.lowercased().contains(q) ||
            $0.author.lowercased().contains(q) ||
            $0.genre.lowercased().contains(q) ||
            $0.keywords.contains(where: { $0.lowercased().contains(q) })
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Search Input Field
            searchFieldSection
            
            // Search Results Preview
            VStack(spacing: 8) {
                ForEach(searchResults.prefix(3)) { book in
                    spotlightResultCard(book: book)
                }
            }
            
            // Re-indexing Action Button
            reindexButtonSection
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
                    Text("СИСТЕМНЫЙ ПОИСК SPOTLIGHT")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("\(indexer.indexedCount) КНИГ В ИНДЕКСЕ")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue))
                }
                
                Text("Поиск со шторки iOS & macOS")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Search Field
    private var searchFieldSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(UIColor.secondaryLabel))
                .font(.caption)
            
            TextField("Симуляция поиска Spotlight (автор, жанр, герой)...", text: $searchQuery)
                .font(.caption)
            
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
    
    // MARK: - Spotlight Result Card
    private func spotlightResultCard(book: SpotlightBookMetadata) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .font(.title3)
                .foregroundColor(theme.primaryAccent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                
                Text("\(book.author) • \(book.genre)")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(book.progressPercent))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryAccent)
                
                Text("\(book.quotesCount) цитат")
                    .font(.system(size: 8))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
        )
    }
    
    // MARK: - Reindex Action Button
    private var reindexButtonSection: some View {
        Button(action: {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            isReindexing = true
            indexer.indexBooks(sampleCatalog)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isReindexing = false
            }
        }) {
            HStack(spacing: 6) {
                if isReindexing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                }
                
                Text(isReindexing ? "Индексация..." : "Переиндексировать CoreSpotlight")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.primaryAccent)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .disabled(isReindexing)
    }
}

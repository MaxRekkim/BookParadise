import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ReadingAlmanacPreviewView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var pages: [AlmanacPageModel] = ReadingAlmanacPDFGenerator.generateAnnualAlmanac(
        year: 2026,
        totalBooks: 42,
        totalPages: 14200,
        topGenre: "Классика"
    )
    @State private var activePageIndex: Int = 0
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Booklet Page Carousel Preview
            TabView(selection: $activePageIndex.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    almanacPageCard(page: page, index: index)
                        .tag(index)
                }
            }
            .frame(height: 180)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
            // Export Button
            exportPDFButton
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
                    Text("ЕЖЕГОДНЫЙ АЛЬМАНАХ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("PDF BOOKLET")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                }
                
                Text("Иллюстрированная летопись года")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "book.pages.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Page Card
    private func almanacPageCard(page: AlmanacPageModel, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(page.pageTitle)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
                
                Text("Стр. \(page.pageIndex) из \(pages.count)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.primaryAccent)
            }
            
            Text(page.subtitle)
                .font(.caption2)
                .italic()
                .foregroundColor(Color(UIColor.secondaryLabel))
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(page.keyHighlights, id: \.self) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(theme.primaryAccent)
                            .frame(width: 4, height: 4)
                        Text(item)
                            .font(.caption)
                            .foregroundColor(Color(UIColor.label))
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(theme.primaryAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Export Button
    private var exportPDFButton: some View {
        Button(action: {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Сформировать и экспортировать PDF")
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
    }
}

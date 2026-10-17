import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct ObsidianVaultSyncView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State public var document: ObsidianVaultDocument = ObsidianVaultSyncEngine.sampleDocument
    @State private var isShowingFullMarkdown: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Vault File Relative Path Badge
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.caption2)
                    .foregroundColor(Color.purple)
                
                Text(document.relativePath)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(UIColor.label))
                
                Spacer()
                
                Button(action: {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = document.fullDocumentContent
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                        Text("Копировать .md")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.purple.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            
            // Markdown Preview Card
            VStack(alignment: .leading, spacing: 8) {
                // Frontmatter Preview
                VStack(alignment: .leading, spacing: 2) {
                    Text("--- YAML FRONTMATTER ---")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(Color.secondary.opacity(0.6))
                    
                    Text(document.frontmatterYAML)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color.purple)
                        .lineSpacing(2)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.purple.opacity(0.06))
                )
                
                // Markdown Callouts Preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("--- PREVIEW CALLOUTS ---")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(Color.secondary.opacity(0.6))
                    
                    HStack(alignment: .top, spacing: 8) {
                        Rectangle()
                            .fill(theme.primaryAccent)
                            .frame(width: 3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("💡 [!quote] Цитата (стр. 287)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(theme.primaryAccent)
                            Text("«Рукописи не горят.»")
                                .font(.caption)
                                .italic()
                                .foregroundColor(Color(UIColor.label))
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(theme.primaryAccent.opacity(0.06))
                    )
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.7))
            )
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
                    Text("СИНХРОНИЗАЦИЯ С OBSIDIAN")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("PKM VAULT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.purple))
                }
                
                Text("Markdown, [[Wikilinks]] и Callouts")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "circle.hexagongrid.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct BookClubThesisView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var prompts: [ClubDiscussionPrompt] = BookClubThesisGenerator.generateAgenda(forBookTitle: "Мастер и Маргарита")
    @State private var bookTitle: String = "Мастер и Маргарита"
    
    public init() {}
    
    private var totalDurationMinutes: Int {
        prompts.reduce(0) { $0 + $1.suggestedMinutes }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Agenda Prompts List
            VStack(spacing: 10) {
                ForEach(prompts) { prompt in
                    promptRow(prompt: prompt)
                }
            }
            
            // Copy Agenda Action
            copyAgendaButton
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
                    Text("ПОВЕСТКА КНИЖНОГО КЛУБА")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("\(totalDurationMinutes) МИНУТ ДИСКУССИИ")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.indigo))
                }
                
                Text("Тезисы к «\(bookTitle)»")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Prompt Row
    private func promptRow(prompt: ClubDiscussionPrompt) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: prompt.category.iconName)
                        .font(.system(size: 10))
                    Text(prompt.category.rawValue)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(prompt.category.accentColor)
                
                Spacer()
                
                Text("\(prompt.suggestedMinutes) мин")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            
            Text(prompt.questionText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(UIColor.label))
            
            if let quote = prompt.anchorQuote {
                Text(quote)
                    .font(.caption2)
                    .italic()
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.7))
        )
    }
    
    // MARK: - Copy Action Button
    private var copyAgendaButton: some View {
        Button(action: {
            #if canImport(UIKit)
            let fullText = prompts.map { "• [\($0.category.rawValue)] \($0.questionText)" }.joined(separator: "\n")
            UIPasteboard.general.string = "Повестка книжного клуба: «\(bookTitle)»\n\n\(fullText)"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11, weight: .bold))
                Text("Скопировать повестку для клуба")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.primaryAccent.opacity(0.12))
            )
            .foregroundColor(theme.primaryAccent)
        }
        .buttonStyle(.plain)
    }
}

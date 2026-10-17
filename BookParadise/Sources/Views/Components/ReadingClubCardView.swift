import SwiftUI
import Darwin

public struct ReadingClubCardView: View {
    @State public var club: ReadingClub
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedChapterFilter: Int = 14
    @State private var showingAllNotes: Bool = false
    
    public init(club: ReadingClub = .sampleClub) {
        _club = State(initialValue: club)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок карточки Клуба
            headerSection
            
            // Прогресс-бар и статус темпа
            paceAndProgressSection
            
            // Список участников клуба
            membersRow
            
            Divider()
            
            // Совместные заметки на полях
            marginNotesSection
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("КНИЖНЫЙ КЛУБ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("LIVE SYNC")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green))
                }
                
                Text(club.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
                
                Text("«\(club.bookTitle)» • \(club.author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(theme.primaryAccent.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.primaryAccent)
            }
        }
    }
    
    // MARK: - Progress & Pace
    private var paceAndProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Глава \(club.currentChapter) из \(club.totalChapters)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(club.averageProgressPercent))% общий прогресс")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryAccent)
            }
            
            // Полоса прогресса
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(LinearGradient(colors: [theme.primaryAccent, theme.secondaryAccent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(club.averageProgressPercent / 100.0), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack(spacing: 6) {
                Image(systemName: "speedometer")
                    .font(.caption2)
                    .foregroundColor(club.paceStatus.statusColor)
                
                Text(club.paceStatus.description)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(club.paceStatus.statusColor)
            }
        }
    }
    
    // MARK: - Members
    private var membersRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Читают сейчас (\(club.members.count))")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(club.members) { member in
                        VStack(spacing: 4) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(theme.primaryAccent.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(member.avatarInitials)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(theme.primaryAccent)
                                    )
                                
                                Image(systemName: member.role.iconName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(member.role.badgeColor)
                                    .background(Circle().fill(Color(UIColor.systemBackground)).frame(width: 14, height: 14))
                                    .offset(x: 2, y: 2)
                            }
                            
                            Text(member.name.components(separatedBy: " ").first ?? member.name)
                                .font(.caption2)
                                .lineLimit(1)
                            
                            Text("\(Int(member.progressPercent))%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 58)
                    }
                }
            }
        }
    }
    
    // MARK: - Margin Notes
    private var marginNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Заметки на полях", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(club.sharedMarginNotes.count) зам.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            ForEach($club.sharedMarginNotes) { $note in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(note.authorName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryAccent)
                        
                        Text("• Гл. \(note.chapterIndex)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if note.isSpoiler {
                            Text(note.spoilerTag ?? "Спойлер")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.purple))
                        }
                    }
                    
                    Text("«\(note.quoteExcerpt)»")
                        .font(.caption)
                        .italic()
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(note.noteText)
                        .font(.subheadline)
                        .foregroundColor(Color(UIColor.label))
                    
                    // Реакции
                    HStack(spacing: 8) {
                        ForEach(note.reactions) { reaction in
                            Button(action: {
                                note.toggleReaction(emoji: reaction.emoji)
                                HapticManager.shared.lightTap()
                            }) {
                                HStack(spacing: 4) {
                                    Text(reaction.emoji)
                                        .font(.caption)
                                    Text("\(reaction.count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(reaction.reactedByUser ? theme.primaryAccent.opacity(0.18) : Color(UIColor.tertiarySystemFill))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(14)
            }
        }
    }
}

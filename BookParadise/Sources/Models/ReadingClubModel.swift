import Foundation
import SwiftUI

// MARK: - Модели Книжного Клуба и Совместных Заметок на Полях
public enum ClubMemberRole: String, Codable, CaseIterable {
    case leader = "Куратор"
    case moderator = "Модератор"
    case reader = "Участник"
    
    public var iconName: String {
        switch self {
        case .leader: return "crown.fill"
        case .moderator: return "shield.fill"
        case .reader: return "book.fill"
        }
    }
    
    public var badgeColor: Color {
        switch self {
        case .leader: return .orange
        case .moderator: return .blue
        case .reader: return .secondary
        }
    }
}

public struct ClubMember: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var avatarInitials: String
    public var progressPercent: Double
    public var currentChapter: Int
    public var role: ClubMemberRole
    public var lastActive: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        avatarInitials: String,
        progressPercent: Double = 0.0,
        currentChapter: Int = 1,
        role: ClubMemberRole = .reader,
        lastActive: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatarInitials = avatarInitials
        self.progressPercent = max(0.0, min(100.0, progressPercent))
        self.currentChapter = max(1, currentChapter)
        self.role = role
        self.lastActive = lastActive
    }
}

public struct ClubNoteReaction: Identifiable, Codable, Equatable {
    public var id: String { emoji }
    public let emoji: String
    public var count: Int
    public var reactedByUser: Bool
    
    public init(emoji: String, count: Int = 1, reactedByUser: Bool = false) {
        self.emoji = emoji
        self.count = count
        self.reactedByUser = reactedByUser
    }
}

public struct SocialMarginNote: Identifiable, Codable, Equatable {
    public let id: UUID
    public let authorId: UUID
    public var authorName: String
    public var authorInitials: String
    public var chapterIndex: Int
    public var pageOffset: Int
    public var cfiAnchor: String?
    public var quoteExcerpt: String
    public var noteText: String
    public var isSpoiler: Bool
    public var spoilerTag: String?
    public var createdAt: Date
    public var reactions: [ClubNoteReaction]
    
    public init(
        id: UUID = UUID(),
        authorId: UUID = UUID(),
        authorName: String,
        authorInitials: String,
        chapterIndex: Int,
        pageOffset: Int = 1,
        cfiAnchor: String? = nil,
        quoteExcerpt: String,
        noteText: String,
        isSpoiler: Bool = false,
        spoilerTag: String? = nil,
        createdAt: Date = Date(),
        reactions: [ClubNoteReaction] = []
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.authorInitials = authorInitials
        self.chapterIndex = chapterIndex
        self.pageOffset = pageOffset
        self.cfiAnchor = cfiAnchor
        self.quoteExcerpt = quoteExcerpt
        self.noteText = noteText
        self.isSpoiler = isSpoiler
        self.spoilerTag = spoilerTag
        self.createdAt = createdAt
        self.reactions = reactions
    }
    
    public mutating func toggleReaction(emoji: String) {
        if let idx = reactions.firstIndex(where: { $0.emoji == emoji }) {
            if reactions[idx].reactedByUser {
                reactions[idx].count = max(0, reactions[idx].count - 1)
                reactions[idx].reactedByUser = false
                if reactions[idx].count == 0 {
                    reactions.remove(at: idx)
                }
            } else {
                reactions[idx].count += 1
                reactions[idx].reactedByUser = true
            }
        } else {
            reactions.append(ClubNoteReaction(emoji: emoji, count: 1, reactedByUser: true))
        }
    }
}

public enum ClubPaceStatus: Equatable {
    case ahead(days: Int)
    case onTrack
    case behind(days: Int)
    
    public var description: String {
        switch self {
        case .ahead(let days): return "Опережает план на \(days) дн."
        case .onTrack: return "Строго по графику"
        case .behind(let days): return "Отставание на \(days) дн."
        }
    }
    
    public var statusColor: Color {
        switch self {
        case .ahead: return .green
        case .onTrack: return .blue
        case .behind: return .orange
        }
    }
}

public struct ReadingClub: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var bookTitle: String
    public var author: String
    public var currentChapter: Int
    public var totalChapters: Int
    public var startDate: Date
    public var targetFinishDate: Date
    public var members: [ClubMember]
    public var sharedMarginNotes: [SocialMarginNote]
    
    public init(
        id: UUID = UUID(),
        title: String,
        bookTitle: String,
        author: String,
        currentChapter: Int = 1,
        totalChapters: Int = 20,
        startDate: Date = Date(),
        targetFinishDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
        members: [ClubMember] = [],
        sharedMarginNotes: [SocialMarginNote] = []
    ) {
        self.id = id
        self.title = title
        self.bookTitle = bookTitle
        self.author = author
        self.currentChapter = max(1, currentChapter)
        self.totalChapters = max(1, totalChapters)
        self.startDate = startDate
        self.targetFinishDate = targetFinishDate
        self.members = members
        self.sharedMarginNotes = sharedMarginNotes
    }
    
    // Средний прогресс клуба
    public var averageProgressPercent: Double {
        guard !members.isEmpty else { return 0.0 }
        let sum = members.reduce(0.0) { $0 + $1.progressPercent }
        return sum / Double(members.count)
    }
    
    // Темпоритм и статус клуба
    public var paceStatus: ClubPaceStatus {
        let totalDuration = targetFinishDate.timeIntervalSince(startDate)
        guard totalDuration > 0 else { return .onTrack }
        
        let elapsed = Date().timeIntervalSince(startDate)
        let expectedProgress = max(0.0, min(1.0, elapsed / totalDuration)) * 100.0
        let delta = averageProgressPercent - expectedProgress
        
        if delta >= 5.0 {
            let daysAhead = max(1, Int(delta / (100.0 / (totalDuration / 86400.0))))
            return .ahead(days: daysAhead)
        } else if delta <= -5.0 {
            let daysBehind = max(1, Int(abs(delta) / (100.0 / (totalDuration / 86400.0))))
            return .behind(days: daysBehind)
        } else {
            return .onTrack
        }
    }
    
    // Заметки по главам
    public func notes(forChapter chapter: Int) -> [SocialMarginNote] {
        sharedMarginNotes.filter { $0.chapterIndex == chapter }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    // Демо-клуб по умолчанию для первого запуска
    public static var sampleClub: ReadingClub {
        let leader = ClubMember(name: "Анна Ахматова", avatarInitials: "АА", progressPercent: 85.0, currentChapter: 17, role: .leader)
        let member1 = ClubMember(name: "Максим Рекким", avatarInitials: "МР", progressPercent: 70.0, currentChapter: 14, role: .moderator)
        let member2 = ClubMember(name: "Елена Волкова", avatarInitials: "ЕВ", progressPercent: 45.0, currentChapter: 9, role: .reader)
        let member3 = ClubMember(name: "Дмитрий Соколов", avatarInitials: "ДС", progressPercent: 60.0, currentChapter: 12, role: .reader)
        
        let note1 = SocialMarginNote(
            authorName: "Анна Ахматова",
            authorInitials: "АА",
            chapterIndex: 12,
            pageOffset: 4,
            quoteExcerpt: "Человек создан для счастья, как птица для полета...",
            noteText: "Обратите внимание на параллель с античной философией стоицизма в этой главе!",
            isSpoiler: false,
            reactions: [ClubNoteReaction(emoji: "❤️", count: 4, reactedByUser: true), ClubNoteReaction(emoji: "🔥", count: 2, reactedByUser: false)]
        )
        
        let note2 = SocialMarginNote(
            authorName: "Максим Рекким",
            authorInitials: "МР",
            chapterIndex: 14,
            pageOffset: 12,
            quoteExcerpt: "Тайна раскрылась на рассвете у старой башни.",
            noteText: "Неожиданный поворот сюжета! Главный мотив персонажа раскрывается в этой сцене.",
            isSpoiler: true,
            spoilerTag: "Поворот сюжета",
            reactions: [ClubNoteReaction(emoji: "🤯", count: 5, reactedByUser: true)]
        )
        
        return ReadingClub(
            title: "Интеллектуальный Салон «Атлант»",
            bookTitle: "Мастер и Маргарита",
            author: "Михаил Булгаков",
            currentChapter: 14,
            totalChapters: 32,
            members: [leader, member1, member2, member3],
            sharedMarginNotes: [note1, note2]
        )
    }
}

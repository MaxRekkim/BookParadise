import Foundation
import SwiftUI

// MARK: - Категория вопроса для книжного клуба
public enum ClubQuestionCategory: String, Codable, CaseIterable {
    case moralDilemma = "Моральная дилемма"
    case symbolism = "Символизм и Мастерство"
    case philosophicalCore = "Философский нерв"
    case characterPsychology = "Психология героев"
    
    public var iconName: String {
        switch self {
        case .moralDilemma: return "scale.3d"
        case .symbolism: return "sparkles"
        case .philosophicalCore: return "brain.head.profile"
        case .characterPsychology: return "person.2.fill"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .moralDilemma: return .red
        case .symbolism: return .purple
        case .philosophicalCore: return .indigo
        case .characterPsychology: return .orange
        }
    }
}

// MARK: - Тезис / Вопрос для дискуссии
public struct ClubDiscussionPrompt: Identifiable, Codable, Equatable {
    public let id: UUID
    public var category: ClubQuestionCategory
    public var questionText: String
    public var anchorQuote: String?
    public var suggestedMinutes: Int
    
    public init(
        id: UUID = UUID(),
        category: ClubQuestionCategory,
        questionText: String,
        anchorQuote: String? = nil,
        suggestedMinutes: Int = 15
    ) {
        self.id = id
        self.category = category
        self.questionText = questionText
        self.anchorQuote = anchorQuote
        self.suggestedMinutes = suggestedMinutes
    }
}

// MARK: - Генератор тезисов (BookClubThesisGenerator)
public struct BookClubThesisGenerator {
    
    public static func generateAgenda(forBookTitle title: String) -> [ClubDiscussionPrompt] {
        [
            ClubDiscussionPrompt(
                category: .moralDilemma,
                questionText: "Оправдан ли конформизм прокуратора перед лицом государственной необходимости?",
                anchorQuote: "«Трусость, несомненно, один из самых страшных пороков.»",
                suggestedMinutes: 20
            ),
            ClubDiscussionPrompt(
                category: .philosophicalCore,
                questionText: "Почему Мастер заслужил именно 'Покой', а не ослепительный 'Свет'?",
                anchorQuote: "«Он не заслужил света, он заслужил покой.»",
                suggestedMinutes: 25
            ),
            ClubDiscussionPrompt(
                category: .symbolism,
                questionText: "Какую роль играет весенняя гроза над Ершалаимом и Москвой как космологический катарсис?",
                anchorQuote: "«Тьма, пришедшая со Средиземного моря, накрыла ненавидимый прокуратором город.»",
                suggestedMinutes: 15
            ),
            ClubDiscussionPrompt(
                category: .characterPsychology,
                questionText: "Является ли преображение поэта Ивана Бездомного духовным выздоровлением или поражением?",
                anchorQuote: "«Он теперь всё знает и понимает.»",
                suggestedMinutes: 15
            )
        ]
    }
}

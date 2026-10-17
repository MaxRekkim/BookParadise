import Foundation
import SwiftUI

// MARK: - Визуальные темы оформления Книжного Бинго
public enum BingoVisualTheme: String, Codable, CaseIterable {
    case classicParchment = "Винтажный пергамент"
    case midnightGold = "Полуночное золото"
    case botanicalSage = "Ботанический шалфей"
    case nordicSlate = "Северный сланец"
    
    public var primaryColor: Color {
        switch self {
        case .classicParchment: return Color(red: 0.65, green: 0.45, blue: 0.25)
        case .midnightGold: return Color(red: 0.95, green: 0.78, blue: 0.35)
        case .botanicalSage: return Color(red: 0.32, green: 0.55, blue: 0.42)
        case .nordicSlate: return Color(red: 0.35, green: 0.48, blue: 0.62)
        }
    }
    
    public var backgroundColor: Color {
        switch self {
        case .classicParchment: return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .midnightGold: return Color(red: 0.08, green: 0.08, blue: 0.12)
        case .botanicalSage: return Color(red: 0.93, green: 0.96, blue: 0.94)
        case .nordicSlate: return Color(red: 0.94, green: 0.95, blue: 0.97)
        }
    }
    
    public var tileBackgroundColor: Color {
        switch self {
        case .classicParchment: return Color(red: 0.93, green: 0.89, blue: 0.82)
        case .midnightGold: return Color(red: 0.14, green: 0.14, blue: 0.20)
        case .botanicalSage: return Color(red: 0.86, green: 0.91, blue: 0.87)
        case .nordicSlate: return Color(red: 0.88, green: 0.90, blue: 0.94)
        }
    }
    
    public var textColor: Color {
        switch self {
        case .classicParchment: return Color(red: 0.22, green: 0.18, blue: 0.12)
        case .midnightGold: return Color(red: 0.96, green: 0.96, blue: 0.98)
        case .botanicalSage: return Color(red: 0.15, green: 0.25, blue: 0.18)
        case .nordicSlate: return Color(red: 0.12, green: 0.16, blue: 0.22)
        }
    }
}

// MARK: - Плитка матрицы Бинго
public struct BingoMatrixTile: Identifiable, Codable, Equatable {
    public let id: Int
    public let row: Int
    public let col: Int
    public var prompt: String
    public var linkedBookId: Int?
    public var linkedBookTitle: String?
    public var isCompleted: Bool
    public var completedDate: Date?
    
    public init(
        id: Int,
        row: Int,
        col: Int,
        prompt: String,
        linkedBookId: Int? = nil,
        linkedBookTitle: String? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.row = row
        self.col = col
        self.prompt = prompt
        self.linkedBookId = linkedBookId
        self.linkedBookTitle = linkedBookTitle
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }
}

// MARK: - Карточка и Анализатор Матрицы Бинго
public struct ReadingBingoMatrixCard: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var year: Int
    public var dimension: Int // Обычно 5 (для 5x5)
    public var tiles: [BingoMatrixTile]
    public var theme: BingoVisualTheme
    
    public init(
        id: UUID = UUID(),
        title: String = "Книжный Вызов Года",
        year: Int = Calendar.current.component(.year, from: Date()),
        dimension: Int = 5,
        tiles: [BingoMatrixTile] = [],
        theme: BingoVisualTheme = .midnightGold
    ) {
        self.id = id
        self.title = title
        self.year = year
        self.dimension = max(3, dimension)
        self.theme = theme
        
        if tiles.isEmpty {
            self.tiles = Self.generateDefaultTiles(dimension: self.dimension)
        } else {
            self.tiles = tiles
        }
    }
    
    // Получение плитки по координатам (row, col)
    public func tileAt(row: Int, col: Int) -> BingoMatrixTile? {
        tiles.first { $0.row == row && $0.col == col }
    }
    
    // Количество закрытых плиток
    public var completedTilesCount: Int {
        tiles.filter { $0.isCompleted }.count
    }
    
    // Процент завершения
    public var completionPercentage: Double {
        guard !tiles.isEmpty else { return 0.0 }
        return (Double(completedTilesCount) / Double(tiles.count)) * 100.0
    }
    
    // Подсчёт закрытых полных линий (по горизонтали, вертикали и диагоналям)
    public var completedLinesCount: Int {
        var lines = 0
        let D = dimension
        
        // 1. Горизонтальные линии
        for r in 0..<D {
            let rowCompleted = (0..<D).allSatisfy { c in
                tileAt(row: r, col: c)?.isCompleted == true
            }
            if rowCompleted { lines += 1 }
        }
        
        // 2. Вертикальные линии
        for c in 0..<D {
            let colCompleted = (0..<D).allSatisfy { r in
                tileAt(row: r, col: c)?.isCompleted == true
            }
            if colCompleted { lines += 1 }
        }
        
        // 3. Главная диагональ
        let mainDiagCompleted = (0..<D).allSatisfy { i in
            tileAt(row: i, col: i)?.isCompleted == true
        }
        if mainDiagCompleted { lines += 1 }
        
        // 4. Побочная диагональ
        let antiDiagCompleted = (0..<D).allSatisfy { i in
            tileAt(row: i, col: D - 1 - i)?.isCompleted == true
        }
        if antiDiagCompleted { lines += 1 }
        
        return lines
    }
    
    // Фулл-хаус (все 25 плиток закрыты)
    public var hasFullHouseBingo: Bool {
        completedTilesCount == tiles.count && !tiles.isEmpty
    }
    
    // Отметка плитки
    public mutating func toggleTile(id: Int, bookId: Int? = nil, bookTitle: String? = nil) {
        if let idx = tiles.firstIndex(where: { $0.id == id }) {
            tiles[idx].isCompleted.toggle()
            if tiles[idx].isCompleted {
                tiles[idx].completedDate = Date()
                if let bookId = bookId { tiles[idx].linkedBookId = bookId }
                if let bookTitle = bookTitle { tiles[idx].linkedBookTitle = bookTitle }
            } else {
                tiles[idx].completedDate = nil
                tiles[idx].linkedBookId = nil
                tiles[idx].linkedBookTitle = nil
            }
        }
    }
    
    // Генерация эталонной матрицы 5x5 с литературными вызовами
    public static func generateDefaultTiles(dimension: Int = 5) -> [BingoMatrixTile] {
        let prompts5x5: [String] = [
            "Книга в синей обложке", "Более 500 страниц", "Лауреат премии", "О путешествиях", "Дебютный роман",
            "Нон-фикшн / мемуары", "Год твоего рождения", "Одно слово в названии", "События в будущем", "Куплена за обложку",
            "Цитата в самое сердце", "Скандинавский детектив", "СВОБОДНЫЙ ВЫБОР ⭐", "Азиатская литература", "Толще 700 страниц",
            "О дружбе или семье", "Редкий перевод", "Совет от друга", "Есть экранизация", "Классика XIX века",
            "Прочтено за 24 часа", "Книга с иллюстрациями", "Готический роман", "Незнакомый жанр", "Неожиданный финал"
        ]
        
        var generated: [BingoMatrixTile] = []
        var idCounter = 0
        
        for r in 0..<dimension {
            for c in 0..<dimension {
                let index = r * dimension + c
                let prompt = index < prompts5x5.count ? prompts5x5[index] : "Книга #\(index + 1)"
                
                // Центр 5x5 (r=2, c=2) - свободная клетка
                let isCenter = (dimension == 5 && r == 2 && c == 2)
                let initialCompleted = isCenter
                
                generated.append(
                    BingoMatrixTile(
                        id: idCounter,
                        row: r,
                        col: c,
                        prompt: prompt,
                        isCompleted: initialCompleted,
                        completedDate: initialCompleted ? Date() : nil
                    )
                )
                idCounter += 1
            }
        }
        
        return generated
    }
}

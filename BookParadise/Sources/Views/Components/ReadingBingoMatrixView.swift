import SwiftUI

public struct ReadingBingoMatrixView: View {
    @State public var card: ReadingBingoMatrixCard
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTile: BingoMatrixTile? = nil
    @State private var showingExportSheet: Bool = false
    
    public init(card: ReadingBingoMatrixCard = ReadingBingoMatrixCard()) {
        _card = State(initialValue: card)
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок и счётчик Бинго
            headerSection
            
            // Тематический переключатель палитры
            themePickerSection
            
            // 5x5 Сетка Бинго
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(card.tiles) { tile in
                    tileCell(tile)
                }
            }
            .padding(10)
            .background(card.theme.backgroundColor)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(card.theme.primaryColor.opacity(0.35), lineWidth: 1.5)
            )
            
            // Нижняя панель статистики и экспорта
            footerStatsSection
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("КНИЖНОЕ БИНГО \(String(card.year))")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(card.theme.primaryColor)
                        .tracking(1.2)
                    
                    if card.completedLinesCount > 0 {
                        Text("\(card.completedLinesCount) ЛИНИЙ • BINGO!")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange))
                    }
                }
                
                Text(card.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            // Процент закрытия
            ZStack {
                Circle()
                    .stroke(Color(UIColor.tertiarySystemFill), lineWidth: 4)
                    .frame(width: 44, height: 44)
                
                Circle()
                    .trim(from: 0, to: CGFloat(card.completionPercentage / 100.0))
                    .stroke(card.theme.primaryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(card.completionPercentage))%")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(card.theme.primaryColor)
            }
        }
    }
    
    // MARK: - Theme Picker
    private var themePickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BingoVisualTheme.allCases, id: \.self) { t in
                    Button(action: {
                        card.theme = t
                        HapticManager.shared.lightTap()
                    }) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(t.primaryColor)
                                .frame(width: 8, height: 8)
                            Text(t.rawValue)
                                .font(.caption2)
                                .fontWeight(card.theme == t ? .bold : .medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(card.theme == t ? t.primaryColor.opacity(0.18) : Color(UIColor.tertiarySystemFill))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Tile Cell
    private func tileCell(_ tile: BingoMatrixTile) -> some View {
        Button(action: {
            card.toggleTile(id: tile.id)
            HapticManager.shared.lightTap()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tile.isCompleted ? card.theme.primaryColor.opacity(0.22) : card.theme.tileBackgroundColor)
                    .aspectRatio(1.0, contentMode: .fit)
                
                VStack(spacing: 2) {
                    if tile.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(card.theme.primaryColor)
                    }
                    
                    Text(tile.prompt)
                        .font(.system(size: 8, weight: tile.isCompleted ? .bold : .medium))
                        .foregroundColor(tile.isCompleted ? card.theme.primaryColor : card.theme.textColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 2)
                }
                .padding(2)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Footer Stats
    private var footerStatsSection: some View {
        HStack {
            Text("Закрыто: \(card.completedTilesCount) из \(card.tiles.count) заданий")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            ShareLink(
                item: "Моё Книжное Бинго \(card.year) в приложении Книжный Рай! Закрыто \(card.completedTilesCount) из \(card.tiles.count) заданий, линий: \(card.completedLinesCount)!",
                preview: SharePreview("Книжное Бинго \(card.year)", image: Image(systemName: "square.grid.3x3.fill"))
            ) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Поделиться")
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(card.theme.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(card.theme.primaryColor.opacity(0.12))
                .cornerRadius(8)
            }
        }
    }
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct LiteraryPantheonView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State public var trophies: [PantheonTrophy] = LiteraryPantheonCatalog.defaultTrophies
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // 2x2 Grid of Trophies
            trophyGrid
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
                    Text("ПАНТЕОН ЛИТЕРАТУРНОЙ СЛАВЫ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("HALL OF FAME")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                }
                
                Text("Триумфы и достижения читателя")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Trophy Grid
    private var trophyGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(trophies) { trophy in
                trophyCard(trophy: trophy)
            }
        }
    }
    
    private func trophyCard(trophy: PantheonTrophy) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: trophy.tier.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Image(systemName: trophy.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(trophy.tier.rawValue)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            
            Text(trophy.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor.label))
            
            Text(trophy.description)
                .font(.system(size: 9))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .lineLimit(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
        )
    }
}

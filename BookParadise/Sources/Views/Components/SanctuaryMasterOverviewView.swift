import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct SanctuaryMasterOverviewView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State public var stats: SanctuaryMasterStats = SanctuaryMasterStats()
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Hero Banner
            heroCelebrationSection
            
            // Core Milestone Pillars (Books, Pages, Hours, Entropy)
            milestonePillarsGrid
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(UIColor.secondarySystemGroupedBackground),
                            theme.primaryAccent.opacity(colorScheme == .dark ? 0.08 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.primaryAccent.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: theme.primaryAccent.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 16, x: 0, y: 6)
        )
    }
    
    // MARK: - Hero Celebration Section
    private var heroCelebrationSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [theme.primaryAccent, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("THE SOVEREIGN SANCTUARY")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.4)
                    
                    Text("v4.4.0")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(theme.primaryAccent))
                }
                
                Text("Книжный Рай: Эра Совершенства")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Milestone Pillars Grid
    private var milestonePillarsGrid: some View {
        HStack(spacing: 10) {
            pillarCard(title: "Книг в базе", value: "\(stats.totalBooksInLibrary)", subtitle: "Шедевры", color: .purple)
            pillarCard(title: "Страниц", value: "\(stats.totalPagesCompleted)", subtitle: "Прочитано", color: .blue)
            pillarCard(title: "Часов потока", value: "\(Int(stats.totalReadingHours))", subtitle: "Глубина", color: .orange)
            pillarCard(title: "Энтропия", value: String(format: "%.2f", stats.shannonEntropy), subtitle: "Шеннон", color: .green)
        }
    }
    
    private func pillarCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(UIColor.label))
            Text(subtitle)
                .font(.system(size: 7))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.7))
        )
    }
}

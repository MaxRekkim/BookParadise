import SwiftUI

public struct ExecutiveQuotaRingAndMixView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @AppStorage("annualGoalBooks") private var annualGoal: Int = 30
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    private var readCount: Int { viewModel.stats.readBooks }
    private var inProgressCount: Int { viewModel.readingNowBooks.count }
    private var plannedCount: Int { viewModel.books.filter { $0.status == .notStarted }.count }
    private var totalCount: Int { viewModel.books.count }
    
    private var goalProgress: Double {
        guard annualGoal > 0 else { return 0.0 }
        return min(1.0, Double(readCount) / Double(annualGoal))
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // 1. Левая карточка: Кольцевой индикатор годовой цели (Emerald glow)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Цель года")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(4)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 7)
                    
                    Circle()
                        .trim(from: 0, to: goalProgress)
                        .stroke(
                            Color(red: 0.90, green: 0.72, blue: 0.23),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 1) {
                        Text("\(Int(goalProgress * 100))%")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("\(readCount)/\(annualGoal)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(width: 80, height: 80)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                Text("2026 Challenge")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
            .padding(14)
            .frame(width: 135, height: 180)
            .background(Color(red: 0.12, green: 0.23, blue: 0.18))
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            // 2. Правая карточка: Спектр библиотеки (Library Mix Bar)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Спектр библиотеки")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Text("\(totalCount) книг")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(UIColor.label))
                
                Text("в вашей коллекции")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Мультисегментный бар
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if totalCount > 0 {
                            if readCount > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.90, green: 0.72, blue: 0.23))
                                    .frame(width: max(4, geo.size.width * CGFloat(readCount) / CGFloat(totalCount)))
                            }
                            if inProgressCount > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.85, green: 0.33, blue: 0.18))
                                    .frame(width: max(4, geo.size.width * CGFloat(inProgressCount) / CGFloat(totalCount)))
                            }
                            if plannedCount > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 0.12, green: 0.23, blue: 0.18))
                                    .frame(width: max(4, geo.size.width * CGFloat(plannedCount) / CGFloat(totalCount)))
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: geo.size.width)
                        }
                    }
                }
                .frame(height: 14)
                
                Spacer()
                
                // Легенда
                HStack {
                    legendItem(color: Color(red: 0.90, green: 0.72, blue: 0.23), title: "Прочитано", count: readCount)
                    Spacer()
                    legendItem(color: Color(red: 0.85, green: 0.33, blue: 0.18), title: "Читаю", count: inProgressCount)
                    Spacer()
                    legendItem(color: Color(red: 0.12, green: 0.23, blue: 0.18), title: "В планах", count: plannedCount)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }
    
    private func legendItem(color: Color, title: String, count: Int) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(title) \(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
        }
    }
}

import SwiftUI

public struct CyclesView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @State private var expandedCycleName: String? = nil
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Фильтры циклов: Все, Завершенные, В процессе, Не начатые
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CycleFilter.allCases) { filter in
                            let isSelected = viewModel.cycleFilter == filter
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.cycleFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.orange : Color(UIColor.secondarySystemGroupedBackground))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .cornerRadius(14)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.normalizedCycles) { cycle in
                            cycleCard(cycle)
                        }
                    }
                    .padding()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Циклы (\(viewModel.normalizedCycles.count))")
            .refreshable {
                await viewModel.syncWithCloud()
            }
        }
    }
    
    // MARK: - Карточка цикла
    private func cycleCard(_ cycle: BookCycle) -> some View {
        let isExpanded = expandedCycleName == cycle.id
        
        return VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedCycleName = nil
                    } else {
                        expandedCycleName = cycle.id
                    }
                }
            }) {
                HStack(alignment: .center, spacing: 12) {
                    // Круговой прогресс
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 4)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(min(1.0, cycle.completionPercent / 100.0)))
                            .stroke(
                                cycle.isCompleted ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 44, height: 44)
                        
                        Text("\(Int(cycle.completionPercent))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cycle.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(cycle.readBooks) из \(cycle.totalBooks) прочитано")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(Circle())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Линейный прогресс
            ProgressView(value: cycle.completionPercent, total: 100.0)
                .tint(cycle.isCompleted ? .green : .orange)
            
            // Раскрывающийся список книг цикла с галочками
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                    ForEach(cycle.bookList) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.isRead ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isRead ? .green : .secondary)
                                .font(.subheadline)
                            
                            Text(item.cycleNumber != "-" ? "#\(item.cycleNumber)" : "—")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .frame(width: 28, alignment: .leading)
                            
                            Text(item.title)
                                .font(.subheadline)
                                .foregroundColor(item.isRead ? .secondary : .primary)
                                .strikethrough(item.isRead)
                                .lineLimit(1)
                            
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

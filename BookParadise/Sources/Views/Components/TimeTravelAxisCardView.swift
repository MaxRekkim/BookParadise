import SwiftUI

// MARK: - Интерактивная лента литературных эпох (Time Travel Axis)
public struct TimeTravelAxisCardView: View {
    public let books: [Book]
    
    @State private var selectedEpoch: LiteraryEpoch? = nil
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(books: [Book]) {
        self.books = books
    }
    
    private var clusters: [EpochCluster] {
        TimeTravelAxisEngine.clusterBooksByEpoch(books: books)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Заголовок карточки
            HStack(spacing: 8) {
                Image(systemName: "hourglass.bottomhalf.filled")
                    .foregroundColor(.indigo)
                    .font(.title3)
                
                Text("Шкала литературных эпох")
                    .font(.headline)
                
                Spacer()
                
                Text("Путешествие во времени")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text("Хронологический разрез вашей библиотеки: от античных мыслителей до современной прозы.")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            // Горизонтальная интерактивная ось времени
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(clusters) { cluster in
                        EpochNodeView(
                            cluster: cluster,
                            isSelected: selectedEpoch == cluster.epoch
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                if selectedEpoch == cluster.epoch {
                                    selectedEpoch = nil
                                } else {
                                    selectedEpoch = cluster.epoch
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
            }
            
            // Детальный список книг выбранной эпохи
            if let epoch = selectedEpoch,
               let cluster = clusters.first(where: { $0.epoch == epoch }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Книги эпохи: **\(epoch.rawValue)**")
                            .font(.caption)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(cluster.books.count) шт.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(cluster.books.prefix(8)) { b in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(b.title)
                                        .font(.caption2)
                                        .bold()
                                        .lineLimit(1)
                                    Text(b.author)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Элемент эпохи на оси времени
fileprivate struct EpochNodeView: View {
    let cluster: EpochCluster
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Круглая иконка с годом
            ZStack {
                Circle()
                    .fill(cluster.epoch.color.opacity(isSelected ? 0.3 : 0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: cluster.epoch.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(cluster.epoch.color)
                
                // Бейдж количества книг
                Circle()
                    .fill(cluster.epoch.color)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Text("\(cluster.books.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 16, y: -16)
            }
            .overlay(
                Circle()
                    .stroke(cluster.epoch.color, lineWidth: isSelected ? 2 : 0)
            )
            
            VStack(spacing: 2) {
                Text(cluster.epoch.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
                
                Text(cluster.epoch.eraPeriodString)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                
                Text("\(Int(cluster.percentage))%")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(cluster.epoch.color)
            }
        }
        .padding(.vertical, 4)
    }
}

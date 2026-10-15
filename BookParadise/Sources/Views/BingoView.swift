import SwiftUI

public struct BingoView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @State private var isShowingAddPlanSelector: Bool = false
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    private var plannedBooksForMonth: [BingoItem] {
        viewModel.bingoItemsForSelectedMonth
    }
    
    private var totalPlannedPages: Int {
        plannedBooksForMonth.reduce(0) { $0 + $1.totalPages }
    }
    
    private var completedBooksCount: Int {
        plannedBooksForMonth.filter { item in
            if let book = viewModel.books.first(where: { $0.id == item.id || $0.title == item.title }) {
                return book.status == .read
            }
            return false
        }.count
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Переключатель месяцев
                monthTabsBar
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Сводка месяца
                        monthSummaryCard
                        
                        // Список книг месяца
                        if plannedBooksForMonth.isEmpty {
                            emptyMonthView
                        } else {
                            VStack(spacing: 12) {
                                ForEach(plannedBooksForMonth) { item in
                                    bingoBookCard(item)
                                }
                            }
                        }
                        
                        // Кнопка «+ Добавить в план месяца»
                        Button(action: {
                            isShowingAddPlanSelector = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Добавить в план месяца (\(viewModel.selectedBingoMonth))")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Планы и Бинго")
            .sheet(isPresented: $isShowingAddPlanSelector) {
                SelectBookForPlanSheet(viewModel: viewModel, month: viewModel.selectedBingoMonth)
            }
            .refreshable {
                await viewModel.syncWithCloud()
            }
        }
    }
    
    // MARK: - Месячные табы
    private var monthTabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableBingoMonths, id: \.self) { month in
                    let isSelected = viewModel.selectedBingoMonth == month
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.selectedBingoMonth = month
                        }
                    }) {
                        Text(month)
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
    }
    
    // MARK: - Сводная карточка месяца
    private var monthSummaryCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("План: \(viewModel.selectedBingoMonth)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Text("\(plannedBooksForMonth.count) книг / \(totalPlannedPages) стр.")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Закрыто:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(completedBooksCount) из \(plannedBooksForMonth.count)")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Карточка книги в Бинго
    private func bingoBookCard(_ item: BingoItem) -> some View {
        let matchingBook = viewModel.books.first(where: { $0.id == item.id || $0.title == item.title })
        let isRead = matchingBook?.status == .read
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                BookCoverView(
                    coverURL: matchingBook?.cleanCoverURL,
                    title: item.title,
                    author: item.author,
                    cornerRadius: 8
                )
                .frame(width: 50, height: 75)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    Text(item.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Text("\(item.totalPages) стр.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if isRead {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Прочитано")
                            }
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            // Степпер плана дней на книгу
            HStack {
                Text("План (дней):")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Button(action: {
                        viewModel.updateBingoPlanDays(item: item, newDays: item.planDays - 1)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(item.planDays)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .frame(minWidth: 28)
                    
                    Button(action: {
                        viewModel.updateBingoPlanDays(item: item, newDays: item.planDays + 1)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("План: \(Int(item.plannedPagesPerDay)) стр./день")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let speed = item.speedPagesPerDay, speed > 0 {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(item.isSpeedAheadOfPlan ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                            Text(String(format: "Факт: %.1f стр./день", speed))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(item.isSpeedAheadOfPlan ? .green : .orange)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private var emptyMonthView: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("В месяце «\(viewModel.selectedBingoMonth)» пока нет планов")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// Вспомогательный лист для выбора непрочитанной книги
struct SelectBookForPlanSheet: View {
    @ObservedObject var viewModel: LibraryViewModel
    let month: String
    @Environment(\.dismiss) private var dismiss
    @State private var planDays: Int = 4
    
    private var unreadBooks: [Book] {
        viewModel.books.filter { $0.status != .read }
    }
    
    var body: some View {
        NavigationStack {
            List(unreadBooks) { book in
                Button(action: {
                    viewModel.addToBingo(book: book, month: month, planDays: planDays)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        BookCoverView(
                            coverURL: book.cleanCoverURL,
                            title: book.title,
                            author: book.author,
                            genre: book.genre,
                            cornerRadius: 6
                        )
                        .frame(width: 40, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text(book.author)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(book.totalPages) стр.")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "plus.circle")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Добавить в «\(month)»")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

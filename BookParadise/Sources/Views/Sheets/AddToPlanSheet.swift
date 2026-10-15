import SwiftUI
import UIKit

public struct AddToPlanSheet: View {
    @ObservedObject public var viewModel: LibraryViewModel
    public let book: Book
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMonth: String
    @State private var planDays: Int = 4
    
    public init(viewModel: LibraryViewModel, book: Book) {
        self.viewModel = viewModel
        self.book = book
        _selectedMonth = State(initialValue: book.planMonth ?? viewModel.selectedBingoMonth)
    }
    
    private var pagesPerDayPlanned: Double {
        return Double(book.totalPages) / Double(max(1, planDays))
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Карточка книги
                HStack(spacing: 14) {
                    BookCoverView(
                        coverURL: book.cleanCoverURL,
                        title: book.title,
                        author: book.author,
                        genre: book.genre,
                        cornerRadius: 8
                    )
                    .frame(width: 55, height: 82)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Всего: \(book.totalPages) стр.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Выбор месяца
                VStack(alignment: .leading, spacing: 10) {
                    Text("Месяц для чтения:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.availableBingoMonths, id: \.self) { month in
                                Button(action: { selectedMonth = month }) {
                                    Text(month)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(selectedMonth == month ? Color.orange : Color(UIColor.tertiarySystemFill))
                                        .foregroundColor(selectedMonth == month ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                // Дней на книгу и расчетная скорость
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("План (дней на книгу):")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Сколько дней планируете читать")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        HStack(spacing: 14) {
                            Button(action: { if planDays > 1 { planDays -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                            
                            Text("\(planDays)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(minWidth: 32)
                            
                            Button(action: { planDays += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Страниц в день по плану:")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f стр./день", pagesPerDayPlanned))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: savePlan) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Добавить в план месяца")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.bottom, 8)
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Планирование чтения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
    
    private func savePlan() {
        viewModel.addToBingo(book: book, month: selectedMonth, planDays: planDays)
        dismiss()
    }
}

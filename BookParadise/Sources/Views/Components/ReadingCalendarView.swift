import SwiftUI

public struct ReadingCalendarView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @State private var selectedMonthIndex: Int = Calendar.current.component(.month, from: Date())
    
    private let months = [
        "Янв", "Фев", "Мар", "Апр", "Май", "Июн",
        "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"
    ]
    
    private let daysOfWeek = ["ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ", "ВС"]
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Календарь активности (2026)")
                    .font(.headline)
                Spacer()
                
                // Навигация по месяцам со стрелочками и меню
                HStack(spacing: 4) {
                    // Кнопка Предыдущий месяц (<)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selectedMonthIndex > 1 {
                                selectedMonthIndex -= 1
                            } else {
                                selectedMonthIndex = 12
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Circle())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Название месяца (с быстрым меню выбора)
                    Menu {
                        ForEach(1...12, id: \.self) { m in
                            Button(action: { selectedMonthIndex = m }) {
                                Text(months[m - 1])
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(months[selectedMonthIndex - 1])
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                    }
                    
                    // Кнопка Следующий месяц (>)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selectedMonthIndex < 12 {
                                selectedMonthIndex += 1
                            } else {
                                selectedMonthIndex = 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Circle())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Заголовки дней недели ПН-ВСК
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Сетка дней месяца
            let days = generateDaysForMonth(selectedMonthIndex, year: 2026)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(days, id: \.id) { item in
                    if let dayNum = item.dayNumber {
                        let isReadDay = isReadingDay(year: 2026, month: selectedMonthIndex, day: dayNum)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isReadDay ? Color.orange.opacity(0.85) : Color(UIColor.tertiarySystemFill))
                                .frame(height: 32)
                            
                            Text("\(dayNum)")
                                .font(.system(size: 11, weight: isReadDay ? .bold : .regular))
                                .foregroundColor(isReadDay ? .white : .primary)
                        }
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange.opacity(0.85))
                        .frame(width: 8, height: 8)
                    Text("Дни чтения")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(UIColor.tertiarySystemFill))
                        .frame(width: 8, height: 8)
                    Text("Без чтения")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                let activeDaysCount = countActiveDaysInMonth(year: 2026, month: selectedMonthIndex)
                Text("\(activeDaysCount) акт. дн.")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Расчет активности по интервалам [startDate, endDate]
    private func isReadingDay(year: Int, month: Int, day: Int) -> Bool {
        let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
        
        for book in viewModel.books {
            guard let start = book.startDate, !start.isEmpty else { continue }
            let end = (book.endDate != nil && !book.endDate!.isEmpty) ? book.endDate! : (book.status == .inProgress ? "2026-12-31" : start)
            
            if dateStr >= start && dateStr <= end {
                return true
            }
        }
        return false
    }
    
    private func countActiveDaysInMonth(year: Int, month: Int) -> Int {
        var count = 0
        let daysInMonth = getDaysInMonth(month: month, year: year)
        for d in 1...daysInMonth {
            if isReadingDay(year: year, month: month, day: d) {
                count += 1
            }
        }
        return count
    }
    
    private struct CalendarDayItem: Identifiable {
        let id = UUID()
        let dayNumber: Int?
    }
    
    private func generateDaysForMonth(_ month: Int, year: Int) -> [CalendarDayItem] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // ПН
        
        var comp = DateComponents()
        comp.year = year
        comp.month = month
        comp.day = 1
        
        guard let firstDate = calendar.date(from: comp) else { return [] }
        
        // Определение смещения для ПН
        let weekday = calendar.component(.weekday, from: firstDate)
        // 1=ВС, 2=ПН, 3=ВТ, 4=СР, 5=ЧТ, 6=ПТ, 7=СБ
        let offset = (weekday == 1) ? 6 : (weekday - 2)
        
        let daysCount = getDaysInMonth(month: month, year: year)
        
        var items: [CalendarDayItem] = []
        for _ in 0..<offset {
            items.append(CalendarDayItem(dayNumber: nil))
        }
        for d in 1...daysCount {
            items.append(CalendarDayItem(dayNumber: d))
        }
        return items
    }
    
    private func getDaysInMonth(month: Int, year: Int) -> Int {
        var comp = DateComponents()
        comp.year = year
        comp.month = month
        let calendar = Calendar.current
        guard let date = calendar.date(from: comp),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
}

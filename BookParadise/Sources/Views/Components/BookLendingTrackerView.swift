import SwiftUI
import UIKit

public struct BookLendingTrackerView: View {
    @ObservedObject private var lendingManager = LendingManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCalendarExportAlert: Bool = false
    @State private var exportedCalendarTitle: String = ""
    
    public init() {}
    
    // Вычисление рейтинга доверия по активным и завершенным записям
    private var trustMetrics: (score: Double, tier: LendingTrustTier) {
        let total = lendingManager.records.count
        let returned = lendingManager.records.filter { $0.isReturned }.count
        let overdue = lendingManager.activeRecords.filter { $0.isOverdue }.count
        return LendingTrustScoreEngine.calculateTrustScore(
            totalLoans: total,
            onTimeReturns: returned,
            activeOverdue: overdue,
            damagedReturns: 0
        )
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок и карточка доверия заёмщиков
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("ТРЕКЕР АРЕНДЫ И ВОЗВРАТА")
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundColor(theme.primaryAccent)
                            .tracking(1.2)
                    }
                    
                    Text("Книги у друзей")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                }
                
                Spacer()
                
                // Бейдж доверия заёмщика
                HStack(spacing: 6) {
                    Image(systemName: trustMetrics.tier.iconName)
                        .font(.caption)
                    Text("\(Int(trustMetrics.score))%")
                        .font(.caption)
                        .fontWeight(.heavy)
                }
                .foregroundColor(trustMetrics.tier.tierColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(trustMetrics.tier.tierColor.opacity(0.12))
                .clipShape(Capsule())
            }
            
            // Список активных заёмов
            if lendingManager.activeRecords.isEmpty {
                emptyLendingBanner
            } else {
                VStack(spacing: 12) {
                    ForEach(lendingManager.activeRecords.prefix(3)) { record in
                        activeLoanCard(record: record)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
        )
        .alert("Событие Календаря", isPresented: $showingCalendarExportAlert) {
            Button("Отлично", role: .cancel) {}
        } message: {
            Text("Событие напоминания для «\(exportedCalendarTitle)» сформировано в формате Apple iCalendar (.ics) и готово к импорту.")
        }
    }
    
    private var emptyLendingBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Все книги на месте")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Ни одной книги сейчас нет на руках у друзей.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(14)
    }
    
    private func activeLoanCard(record: BookLendingRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.bookTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(record.personName)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if let contact = record.contact, !contact.isEmpty {
                            Text("(\(contact))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Статус срока
                if record.isOverdue {
                    Text("ПРОСРОЧЕНО")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.red))
                } else if let days = record.daysRemaining {
                    Text("\(days) дн. осталось")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(days <= 3 ? .orange : .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((days <= 3 ? Color.orange : Color.green).opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            
            // Кнопки действий: Вернуть и Экспорт в Календарь
            HStack(spacing: 10) {
                Button(action: {
                    lendingManager.markReturned(recordId: record.id)
                    HapticManager.shared.lightTap()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                        Text("Вернули")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                if let due = record.dueDate {
                    Button(action: {
                        let ics = LendingTrustScoreEngine.generateCalendarEventICS(
                            bookTitle: record.bookTitle,
                            borrowerName: record.personName,
                            dueDate: due,
                            notes: record.notes
                        )
                        UIPasteboard.general.string = ics
                        exportedCalendarTitle = record.bookTitle
                        showingCalendarExportAlert = true
                        HapticManager.shared.lightTap()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                            Text("В Календарь")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.primaryAccent.opacity(0.12))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

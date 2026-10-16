import SwiftUI

public struct LendingListView: View {
    @ObservedObject private var lendingManager = LendingManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var filterSelected: Int = 0 // 0: Активные, 1: История

    public init() {}

    private var activeList: [BookLendingRecord] {
        lendingManager.activeRecords
    }

    private var historyList: [BookLendingRecord] {
        lendingManager.records.filter { $0.isReturned }
            .sorted { ($0.returnDate ?? Date()) > ($1.returnDate ?? Date()) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.paperBackground(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Категория", selection: $filterSelected) {
                        Text("У друзей (\(activeList.count))").tag(0)
                        Text("Возвращены (\(historyList.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if filterSelected == 0 {
                        if activeList.isEmpty {
                            emptyActiveState
                        } else {
                            List {
                                ForEach(activeList) { record in
                                    lendingCard(record: record)
                                        .listRowBackground(theme.cardBackground(for: colorScheme))
                                }
                                .onDelete { indexSet in
                                    for idx in indexSet {
                                        lendingManager.deleteRecord(recordId: activeList[idx].id)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)
                        }
                    } else {
                        if historyList.isEmpty {
                            emptyHistoryState
                        } else {
                            List {
                                ForEach(historyList) { record in
                                    historyCard(record: record)
                                        .listRowBackground(theme.cardBackground(for: colorScheme))
                                }
                                .onDelete { indexSet in
                                    for idx in indexSet {
                                        lendingManager.deleteRecord(recordId: historyList[idx].id)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .scrollContentBackground(.hidden)
                        }
                    }
                }
            }
            .navigationTitle("Книги у друзей")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func lendingCard(record: BookLendingRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.bookTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))

                    HStack(spacing: 4) {
                        Image(systemName: record.type == .lentToFriend ? "arrow.up.right.circle.fill" : "arrow.down.left.circle.fill")
                            .foregroundColor(record.type == .lentToFriend ? .orange : .blue)
                            .font(.caption)

                        Text("\(record.type == .lentToFriend ? "У кого:" : "Взята у:") \(record.personName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let days = record.daysRemaining {
                    if days < 0 {
                        Text("Просрочено \(abs(days)) дн.")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(Capsule())
                    } else {
                        Text("Осталось \(days) дн.")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
            }

            if let contact = record.contact, !contact.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "paperplane.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text(contact)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Divider().padding(.vertical, 4)

            HStack {
                Text("Отдано: \(formattedDate(record.lentDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    withAnimation {
                        lendingManager.markReturned(recordId: record.id)
                    }
                }) {
                    Label("Отметить возврат", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private func historyCard(record: BookLendingRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.bookTitle)
                .font(.subheadline)
                .fontWeight(.bold)

            Text("Был(а) у: \(record.personName)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let rDate = record.returnDate {
                Text("Возвращена: \(formattedDate(rDate))")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 2)
    }

    private var emptyActiveState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.6))

            Text("Все книги дома!")
                .font(.headline)

            Text("Вы пока никому не одалживали книги из своей библиотеки.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var emptyHistoryState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("История возвратов пуста")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

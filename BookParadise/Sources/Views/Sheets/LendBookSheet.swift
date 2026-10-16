import SwiftUI

public struct LendBookSheet: View {
    public let book: Book
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var lendingManager = LendingManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var type: LendingType = .lentToFriend
    @State private var personName: String = ""
    @State private var contact: String = ""
    @State private var hasDueDate: Bool = true
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var notes: String = ""

    public init(book: Book) {
        self.book = book
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Тип операции", selection: $type) {
                        ForEach(LendingType.allCases, id: \.self) { t in
                            Text(t.title).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundColor(theme.primaryAccent)
                        TextField(type == .lentToFriend ? "Имя друга / кому отдана" : "Имя владельца / у кого взята", text: $personName)
                    }

                    HStack {
                        Image(systemName: "phone.circle")
                            .foregroundColor(.secondary)
                        TextField("Контакт (телефон / @telegram)", text: $contact)
                            .keyboardType(.emailAddress)
                    }
                } header: {
                    Text("Контактное лицо")
                }

                Section {
                    Toggle("Установить срок возврата", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker(
                            "Дата возврата",
                            selection: $dueDate,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                    }
                } header: {
                    Text("Срок")
                }

                Section {
                    TextField("Заметки (в каком состоянии, где передали...)", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Примечание")
                }
            }
            .navigationTitle("Одолжить книгу")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        lendingManager.lendBook(
                            book: book,
                            personName: personName,
                            contact: contact,
                            dueDate: hasDueDate ? dueDate : nil,
                            type: type,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}

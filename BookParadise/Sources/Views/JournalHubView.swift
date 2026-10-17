import SwiftUI
import UIKit

/// Главный хаб литературной хроники читателя: объединяет цитаты, заметки, планы чтения и бинго.
public struct JournalHubView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var quotesManager = QuotesManager.shared
    @ObservedObject private var noteStore = ReadingNoteStore.shared

    @State private var selectedSegment: Int = 0 // 0: Цитаты, 1: Заметки, 2: Планы и Бинго
    @State private var isShowingNewNoteSheet: Bool = false
    @State private var isShowingQuotePicker: Bool = false
    @State private var isShowingAddPlanSelector: Bool = false

    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Переключатель разделов Хроники
                Picker("Раздел", selection: $selectedSegment) {
                    Text("Цитаты (\(quotesManager.quotes.count))").tag(0)
                    Text("Заметки (\(noteStore.notes.count))").tag(1)
                    Text("Планы & Бинго").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(Color(UIColor.secondarySystemGroupedBackground))

                Divider()

                // Активное содержимое
                Group {
                    switch selectedSegment {
                    case 0:
                        QuotesGalleryView(viewModel: viewModel, isEmbedded: true)
                    case 1:
                        NotesJournalView(viewModel: viewModel, isEmbedded: true)
                    default:
                        BingoView(viewModel: viewModel, isEmbedded: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Хроника читателя")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if selectedSegment == 0 {
                            Button(action: { isShowingQuotePicker = true }) {
                                Image(systemName: "plus.bubble.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.primaryAccent)
                            }
                            .accessibilityLabel("Добавить цитату")
                        } else if selectedSegment == 1 {
                            Button(action: { isShowingNewNoteSheet = true }) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.primaryAccent)
                            }
                            .accessibilityLabel("Создать заметку")
                        } else {
                            Button(action: { isShowingAddPlanSelector = true }) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.primaryAccent)
                            }
                            .accessibilityLabel("Добавить в план")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingNewNoteSheet) {
                MarkdownEditorView(viewModel: viewModel)
                    .macSheetFrame(large: true)
            }
            .sheet(isPresented: $isShowingQuotePicker) {
                QuickBookPickerSheet(viewModel: viewModel, mode: .quoteScanner)
                    .macSheetFrame()
            }
            .sheet(isPresented: $isShowingAddPlanSelector) {
                SelectBookForPlanSheet(viewModel: viewModel, month: viewModel.selectedBingoMonth)
                    .macSheetFrame()
            }
        }
    }
}

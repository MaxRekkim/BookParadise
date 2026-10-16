import SwiftUI
import UIKit

public struct BookOracleView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject private var oracle = BookOracleManager.shared

    @State private var selectedTab: Int = 0 // 0: Сомелье, 1: Кубик
    @State private var selectedMood: ReadingMood = .cozy
    @State private var selectedTime: AvailableReadingTime = .medium
    @State private var selectedSource: OracleQueueSource = .planned
    @State private var recommendation: BookRecommendation? = nil
    @State private var isRolling: Bool = false

    public var onStartReading: ((Book) -> Void)? = nil

    public init(viewModel: LibraryViewModel, onStartReading: ((Book) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onStartReading = onStartReading
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Переключатель режимов
                    Picker("Режим", selection: $selectedTab) {
                        Text("Подбор сомелье").tag(0)
                        Text("Литературный кубик").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if selectedTab == 0 {
                        sommelierWizardView
                    } else {
                        diceRouletteView
                    }

                    if let rec = recommendation {
                        recommendationResultCard(rec)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Книжный Оракул")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                generateRecommendation()
            }
        }
    }

    // MARK: - Режим 1: Мастер подбора
    private var sommelierWizardView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Настроение
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Какое настроение вы ищете?")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReadingMood.allCases) { mood in
                            Button(action: {
                                selectedMood = mood
                                generateRecommendation()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: mood.icon)
                                    Text(mood.rawValue)
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedMood == mood ? theme.primaryAccent : Color(UIColor.secondarySystemGroupedBackground))
                                .foregroundColor(selectedMood == mood ? .white : .primary)
                                .cornerRadius(20)
                                .shadow(color: selectedMood == mood ? theme.primaryAccent.opacity(0.3) : .clear, radius: 4, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Время
            VStack(alignment: .leading, spacing: 8) {
                Text("2. Сколько у вас есть времени?")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AvailableReadingTime.allCases) { time in
                            Button(action: {
                                selectedTime = time
                                generateRecommendation()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: time.icon)
                                    Text(time.rawValue)
                                }
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedTime == time ? theme.primaryAccent : Color(UIColor.secondarySystemGroupedBackground))
                                .foregroundColor(selectedTime == time ? .white : .primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Источник
            VStack(alignment: .leading, spacing: 8) {
                Text("3. Откуда выбрать?")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                HStack(spacing: 8) {
                    ForEach(OracleQueueSource.allCases) { src in
                        Button(action: {
                            selectedSource = src
                            generateRecommendation()
                        }) {
                            Text(src.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedSource == src ? theme.primaryAccent : Color(UIColor.secondarySystemGroupedBackground))
                                .foregroundColor(selectedSource == src ? .white : .primary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Режим 2: Литературный кубик
    private var diceRouletteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dice.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryAccent)
                .rotationEffect(.degrees(isRolling ? 360 : 0))
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isRolling)

            Text("Не можете определиться среди сотен книг на полке? Доверьтесь случаю!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: rollDice) {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                    Text("Бросить кубик")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(theme.primaryAccent)
                .cornerRadius(12)
                .shadow(color: theme.primaryAccent.opacity(0.3), radius: 6, y: 3)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Карточка рекомендации
    private func recommendationResultCard(_ rec: BookRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                BookCoverView(
                    coverURL: rec.book.cleanCoverURL,
                    title: rec.book.title,
                    author: rec.book.author,
                    genre: rec.book.genre,
                    cornerRadius: 10
                )
                .frame(width: 90, height: 135)
                .shadow(radius: 4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(rec.book.genre.rawValue)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(rec.book.genre.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(rec.book.genre.accentColor.opacity(0.12))
                            .cornerRadius(6)

                        Spacer()

                        Text(rec.book.status.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(rec.book.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    Text(rec.book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "hourglass")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(rec.estimatedTimeToFinish)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 2)
                }
            }

            // Обоснование сомелье
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(theme.primaryAccent)
                    .font(.subheadline)

                Text(rec.justification)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(12)
            .background(theme.primaryAccent.opacity(0.08))
            .cornerRadius(10)

            // Кнопки действия
            HStack(spacing: 10) {
                Button(action: {
                    var updated = rec.book
                    if updated.status != .reading {
                        updated.status = .reading
                        viewModel.updateBook(updated)
                    }
                    dismiss()
                    onStartReading?(updated)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                        Text("Начать читать")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.primaryAccent)
                    .cornerRadius(10)
                }

                Button(action: {
                    if selectedTab == 0 {
                        generateRecommendation()
                    } else {
                        rollDice()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
    }

    private func generateRecommendation() {
        withAnimation(.easeInOut(duration: 0.25)) {
            recommendation = oracle.recommend(
                from: viewModel.books,
                mood: selectedMood,
                time: selectedTime,
                source: selectedSource
            )
        }
    }

    private func rollDice() {
        isRolling = true
        withAnimation(.easeInOut(duration: 0.3)) {
            recommendation = oracle.rollDice(from: viewModel.books)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isRolling = false
        }
    }
}

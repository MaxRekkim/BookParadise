import SwiftUI
import UIKit

public struct DailyMotivationBanner: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private let quotes: [(text: String, author: String)] = [
        ("Чтение — это диалог с лучшими людьми прошедших времен.", "Рене Декарт"),
        ("Книга — это мечта, которую вы держите в руках.", "Нил Гейман"),
        ("Человек, который не читает хороших книг, не имеет преимуществ перед тем, кто не умеет читать.", "Марк Твен"),
        ("Есть преступления хуже, чем сжигать книги. Например — не читать их.", "Рэй Брэдбери"),
        ("Чтение для ума — то же, что физические упражнения для тела.", "Джозеф Аддисон"),
        ("Пара страниц в день — и через год перед вами целая библиотека.", "Книжная мудрость"),
        ("Комната без книг подобна телу без души.", "Марк Туллий Цицерон"),
        ("Я всегда воображал рай чем-то наподобие библиотеки.", "Хорхе Луис Борхес"),
        ("Книги — это корабли мысли, странствующие по волнам времени.", "Фрэнсис Бэкон")
    ]
    
    @State private var quoteIndex: Int = 0
    @State private var isShowingChallenge: Bool = false
    @State private var isShowingQuotesGallery: Bool = false
    @AppStorage("annualGoalBooks") private var annualGoal: Int = 30
    
    public init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
    }
    
    private var currentQuote: (text: String, author: String) {
        quotes[quoteIndex % quotes.count]
    }
    
    private var readCount2026: Int {
        viewModel.stats.readBooks
    }
    
    private var goalPercent: Double {
        guard annualGoal > 0 else { return 0.0 }
        return min(1.0, Double(readCount2026) / Double(annualGoal))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Верхняя плашка: Цитата дня и ссылка на всю галерею
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.title3)
                        .foregroundColor(theme.primaryAccent)
                    
                    Text("Вдохновение дня")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryAccent)
                        .textCase(.uppercase)
                }
                
                Spacer()
                
                Button(action: {
                    isShowingQuotesGallery = true
                }) {
                    HStack(spacing: 4) {
                        Text("Все цитаты")
                            .font(.caption2)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Текст цитаты (нажатие плавно меняет цитату с тактильным откликом)
            VStack(alignment: .leading, spacing: 6) {
                Text("«\(currentQuote.text)»")
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .lineSpacing(3)
                    .foregroundColor(Color(UIColor.label))
                
                HStack {
                    Text("— \(currentQuote.author)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("нажмите для смены")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                #if canImport(UIKit) && !targetEnvironment(macCatalyst)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    quoteIndex = (quoteIndex + 1) % quotes.count
                }
            }
            
            Divider()
            
            // Нижняя строка: Годовая цель с переходом в «Книжный вызов»
            Button(action: {
                isShowingChallenge = true
            }) {
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .foregroundColor(theme.primaryAccent)
                                .font(.caption)
                            Text("Цель 2026:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("\(readCount2026) из \(annualGoal) книг")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(Int(goalPercent * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(theme.primaryAccent)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemFill))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [theme.primaryAccent, theme.secondaryAccent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(goalPercent), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(theme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
        .onAppear {
            let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            let hour = Calendar.current.component(.hour, from: Date())
            quoteIndex = (day + hour) % quotes.count
        }
        .sheet(isPresented: $isShowingChallenge) {
            ReadingChallengeView(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingQuotesGallery) {
            QuotesGalleryView(viewModel: viewModel, onDismiss: {
                isShowingQuotesGallery = false
            })
        }
    }
}

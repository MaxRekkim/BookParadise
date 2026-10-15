import SwiftUI

public struct DailyMotivationBanner: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var theme = ThemeManager.shared
    
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
            // Верхняя плашка: Цитата дня и кнопка обновления
            HStack(alignment: .top) {
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        quoteIndex = (quoteIndex + 1) % quotes.count
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                        Text("Другая")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Текст цитаты
            VStack(alignment: .leading, spacing: 4) {
                Text("«\(currentQuote.text)»")
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .lineSpacing(3)
                    .foregroundColor(Color(UIColor.label))
                
                Text("— \(currentQuote.author)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Нижняя строка: Годовая цель 2026 и активная серия
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
                    
                    Text("\(Int(goalPercent * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(theme.primaryAccent)
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.primaryAccent.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            quoteIndex = dayOfYear % quotes.count
        }
    }
}

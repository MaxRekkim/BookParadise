import SwiftUI

public struct HotReadsBentoView: View {
    @ObservedObject public var viewModel: LibraryViewModel
    @ObservedObject private var sessionManager = ReadingSessionManager.shared
    @Binding public var selectedBookForSession: Book?
    
    public init(viewModel: LibraryViewModel, selectedBookForSession: Binding<Book?>) {
        self.viewModel = viewModel
        self._selectedBookForSession = selectedBookForSession
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text("Книги в фокусе (Hot Reads)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color(red: 0.85, green: 0.33, blue: 0.18))
                        .font(.subheadline)
                }
                
                Spacer()
                
                Text("\(viewModel.readingNowBooks.count) в процессе")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.85, green: 0.33, blue: 0.18))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.85, green: 0.33, blue: 0.18).opacity(0.12))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.readingNowBooks.enumerated()), id: \.element.id) { index, book in
                        bentoCard(for: book, index: index)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ObservedObject private var theme = ThemeManager.shared
    
    private func bentoCard(for book: Book, index: Int) -> some View {
        let remainingTime = sessionManager.estimatedTimeToFinish(remainingPages: book.remainingPages).displayString
        let percent = Int(book.progressPercent)
        
        return VStack(alignment: .leading, spacing: 10) {
            // Кликабельная область для перехода к деталям книги
            NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                VStack(alignment: .leading, spacing: 8) {
                    // 1. Верхний статус времени чтения и стрелка перехода
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10, weight: .bold))
                            Text(remainingTime)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(theme.primaryAccent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(theme.primaryAccent.opacity(0.12))
                        .cornerRadius(7)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.primaryAccent)
                            .padding(5)
                            .background(theme.primaryAccent.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    // 2. Обложка + Название, автор и прогресс
                    HStack(alignment: .top, spacing: 10) {
                        BookCoverView(
                            coverURL: book.cleanCoverURL,
                            title: book.title,
                            author: book.author,
                            genre: book.genre,
                            cornerRadius: 6
                        )
                        .frame(width: 50, height: 75)
                        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(UIColor.label))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Text(book.author)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Spacer(minLength: 4)
                            
                            // Кастомный плавный Capsule-прогрессбар без прямоугольных системных текстур
                            VStack(alignment: .leading, spacing: 3) {
                                GeometryReader { pGeo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(UIColor.tertiarySystemFill))
                                        Capsule()
                                            .fill(theme.primaryAccent)
                                            .frame(width: max(4, pGeo.size.width * CGFloat(min(1.0, book.progressPercent / 100.0))))
                                    }
                                }
                                .frame(height: 5)
                                
                                HStack {
                                    Text("\(percent)%")
                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .foregroundColor(theme.primaryAccent)
                                    Spacer()
                                    Text("\(book.currentPage)/\(book.totalPages) стр.")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // 3. Кнопка Быстрый старт чтения
            Button(action: {
                selectedBookForSession = book
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                    Text("Продолжить чтение")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(theme.primaryAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(theme.primaryAccent.opacity(0.12))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 280, height: 180)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.primaryAccent.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .desktopHover(scale: 1.02, yOffset: -2)
    }
}

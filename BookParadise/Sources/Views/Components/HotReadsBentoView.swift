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
    
    private func bentoCard(for book: Book, index: Int) -> some View {
        let isTerracotta = index % 3 == 1
        let isEmerald = index % 3 == 2
        let bgColor = isTerracotta
            ? Color(red: 0.77, green: 0.31, blue: 0.16)
            : isEmerald
                ? Color(red: 0.12, green: 0.27, blue: 0.22)
                : Color(red: 0.11, green: 0.12, blue: 0.14)
        
        let remainingTime = sessionManager.estimatedTimeToFinish(remainingPages: book.remainingPages).displayString
        let percent = Int(book.progressPercent)
        
        return VStack(alignment: .leading, spacing: 10) {
            // Кликабельная область для перехода к карточке книги
            NavigationLink(destination: BookDetailView(viewModel: viewModel, bookId: book.id)) {
                VStack(alignment: .leading, spacing: 10) {
                    // Верхний статус времени
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                            Text(remainingTime)
                                .font(.system(size: 10, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.16))
                        .cornerRadius(7)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(5)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Название и автор
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(book.author)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    // Прогресс бар
                    HStack(spacing: 8) {
                        ProgressView(value: book.progressPercent / 100.0)
                            .tint(.white)
                            .background(Color.white.opacity(0.2))
                        
                        Text("\(percent)%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Кнопка Быстрый старт чтения (без коллизии с NavigationLink)
            Button(action: {
                selectedBookForSession = book
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                    Text("Продолжить")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.22))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 230, height: 175)
        .background(bgColor)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        .desktopHover(scale: 1.03, yOffset: -3)
    }
}

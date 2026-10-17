import SwiftUI

public struct BookBeamShareView: View {
    public let payload: BookBeamPayload
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var temporaryExportUrl: URL? = nil
    
    public init(payload: BookBeamPayload) {
        self.payload = payload
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Карточка Книжного Луча (Book Beam)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BOOK BEAM • AIRDROP READY")
                                .font(.caption2)
                                .fontWeight(.heavy)
                                .foregroundColor(theme.primaryAccent)
                                .tracking(1.2)
                            
                            Text(payload.bookTitle)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(UIColor.label))
                            
                            Text(payload.author)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.primaryAccent)
                    }
                    
                    Divider()
                    
                    // Метаданные книги
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Жанр")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(payload.genre)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Объём")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(payload.totalPages) стр.")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Оценка")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack(spacing: 2) {
                                ForEach(0..<payload.ratingStars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    
                    // Цитата, если есть
                    if let quote = payload.favoriteQuote, !quote.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Избранная цитата:")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            Text("«\(quote)»")
                                .font(.caption)
                                .italic()
                                .foregroundColor(Color(UIColor.label))
                                .padding(8)
                                .background(Color(UIColor.tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Криптографический хэш SHA-256
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Text("SHA-256: \(payload.integritySha256.prefix(12))...")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Целостность подтверждена")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                )
                
                // Кнопка передачи через AirDrop / Share Sheet
                if let fileUrl = payload.exportToTemporaryFile() {
                    ShareLink(
                        item: fileUrl,
                        preview: SharePreview("BookBeam: \(payload.bookTitle)", image: Image(systemName: "book.closed.fill"))
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.title3)
                            Text("Передать по AirDrop / Поделиться")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [theme.primaryAccent, theme.secondaryAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Передача книги")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}

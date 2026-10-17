import SwiftUI
import UIKit

/// Реалистичный 3D-корешок книги для Виртуальной книжной полки.
/// Создан по канонам физики переплетного дела и роскошных частных библиотек:
/// - Математическая толщина корешка от объема страниц
/// - Тиснение золотой/серебряной фольгой с металлическим блеском
/// - Шелковое ляссе (закладка) с V-образным ласточкиным хвостом
/// - Интерактивное выдвижение книги вперед при тапе
public struct BookSpineView: View {
    public let book: Book
    public var isInteractive: Bool = true
    
    @ObservedObject private var theme = ThemeManager.shared
    @State private var isPulled: Bool = false

    public init(book: Book, isInteractive: Bool = true) {
        self.book = book
        self.isInteractive = isInteractive
    }

    /// Точный математический расчет толщины корешка книги
    public var spineWidth: CGFloat {
        let pages = book.totalPages
        if pages <= 150 {
            return 24.0
        } else if pages <= 350 {
            return 32.0
        } else if pages <= 600 {
            return 42.0
        } else if pages <= 900 {
            return 52.0
        } else {
            return 64.0
        }
    }

    /// Органическая вариация высоты томов на полке (от 158 до 178 pt)
    public var spineHeight: CGFloat {
        let seed = abs(book.id.hashValue) % 6
        return CGFloat(158 + seed * 4)
    }

    /// Выбор благородного переплета на основе жанра книги
    private var spineLeatherColors: [Color] {
        switch book.genre {
        case .classic:
            return [Color(red: 0.42, green: 0.16, blue: 0.16), Color(red: 0.28, green: 0.10, blue: 0.10)] // Бордовый сафьян
        case .detective:
            return [Color(red: 0.16, green: 0.20, blue: 0.28), Color(red: 0.10, green: 0.12, blue: 0.18)] // Полуночный кобальт
        case .sciFi:
            return [Color(red: 0.18, green: 0.28, blue: 0.35), Color(red: 0.12, green: 0.18, blue: 0.24)] // Стальной сапфир
        case .fantasy:
            return [Color(red: 0.16, green: 0.32, blue: 0.24), Color(red: 0.10, green: 0.22, blue: 0.16)] // Изумрудный шелк
        case .biography:
            return [Color(red: 0.38, green: 0.28, blue: 0.18), Color(red: 0.26, green: 0.18, blue: 0.12)] // Теплый орех
        case .history:
            return [Color(red: 0.40, green: 0.22, blue: 0.14), Color(red: 0.28, green: 0.14, blue: 0.08)] // Старинная охра
        case .psychology, .philosophy:
            return [Color(red: 0.28, green: 0.24, blue: 0.32), Color(red: 0.18, green: 0.15, blue: 0.22)] // Королевский аметист
        default:
            return [Color(red: 0.24, green: 0.25, blue: 0.28), Color(red: 0.15, green: 0.16, blue: 0.18)] // Сланцевый базальт
        }
    }

    /// Градиент золотого тиснения для шедевров и любимых книг
    private var goldFoilGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.90, blue: 0.65),
                Color(red: 0.88, green: 0.74, blue: 0.42),
                Color(red: 0.98, green: 0.92, blue: 0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Градиент серебряного тиснения для стандартных томов
    private var silverFoilGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(white: 0.95),
                Color(white: 0.78),
                Color(white: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var isTopRated: Bool {
        book.rating == .star5 || book.rating == .masterpiece
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Шелковое ляссе (закладка) со скошенным V-образным хвостом
            if book.status == .inProgress {
                silkBookmarkRibbon
            }

            // 2. Тело корешка с цилиндрическим 3D-освещением
            ZStack {
                // Кожаная текстура основы
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: spineLeatherColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Цилиндрический светотеневой рельеф корешка (блик по левой трети, тень по краям)
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.45), location: 0.0),
                                .init(color: .white.opacity(0.25), location: 0.22),
                                .init(color: .white.opacity(0.08), location: 0.40),
                                .init(color: .clear, location: 0.60),
                                .init(color: .black.opacity(0.40), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Декоративные бинты (поперечные рельефные ребра переплета)
                VStack {
                    embossedRibGroup
                    Spacer()
                    if isTopRated {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(goldFoilGradient)
                            .shadow(color: .black.opacity(0.6), radius: 1, y: 1)
                    }
                    Spacer()
                    embossedRibGroup
                }
                .padding(.vertical, 10)

                // Фольгированное тиснение названия книги и автора
                VStack(spacing: 4) {
                    Text(book.typographicTitle)
                        .font(.system(size: 10, weight: .semibold, design: .serif))
                        .foregroundStyle(isTopRated ? goldFoilGradient : silverFoilGradient)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.75), radius: 1, x: 0, y: 1)
                        .fixedSize()
                        .rotationEffect(.degrees(-90))
                        .frame(maxHeight: spineHeight - 68)

                    if spineWidth >= 34 {
                        Text(book.typographicAuthor)
                            .font(.system(size: 8, weight: .medium, design: .serif))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.75), radius: 1, x: 0, y: 1)
                            .fixedSize()
                            .rotationEffect(.degrees(-90))
                            .frame(maxHeight: 44)
                    }
                }

                // Деликатный маркер прочитанной книги (золотой микро-щит)
                if book.status == .read {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 5, height: 5)
                                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 0.5))
                                .padding(5)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: spineWidth, height: spineHeight)
            .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(isPulled ? 0.55 : 0.35),
                radius: isPulled ? 6 : 2.5,
                x: isPulled ? 0 : 2,
                y: isPulled ? -4 : 1.5
            )
            .offset(y: isPulled ? -14 : 0)
            .scaleEffect(isPulled ? 1.04 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isPulled)
        }
        .onTapGesture {
            guard isInteractive else { return }
            HapticManager.shared.impact(style: .rigid)
            withAnimation {
                isPulled.toggle()
            }
        }
    }

    /// Декоративные бинты переплета (рельефные полоски)
    private var embossedRibGroup: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(Color.white.opacity(0.32))
                .frame(height: 1)
            Rectangle()
                .fill(Color.black.opacity(0.45))
                .frame(height: 1)
        }
        .padding(.horizontal, 3)
    }

    /// Шелковая закладка-ляссе с ласточкиным хвостом
    private var silkBookmarkRibbon: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.25, blue: 0.20), Color(red: 0.65, green: 0.15, blue: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 6, height: 16)

            // V-образный вырез ленты
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 6, y: 0))
                path.addLine(to: CGPoint(x: 6, y: 5))
                path.addLine(to: CGPoint(x: 3, y: 2))
                path.addLine(to: CGPoint(x: 0, y: 5))
                path.closeSubpath()
            }
            .fill(Color(red: 0.65, green: 0.15, blue: 0.12))
            .frame(width: 6, height: 5)
        }
        .offset(y: 18)
        .shadow(color: .black.opacity(0.3), radius: 1.5, x: 1, y: 2)
    }
}

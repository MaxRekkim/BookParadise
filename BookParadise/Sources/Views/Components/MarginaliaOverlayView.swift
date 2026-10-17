import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Dog-Ear Corner Triangle Shape
public struct DogEarFoldShape: Shape {
    public let size: CGFloat
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        // Top-right triangle corner
        path.move(to: CGPoint(x: rect.maxX - size, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + size))
        path.addLine(to: CGPoint(x: rect.maxX - size, y: rect.minY + size))
        path.closeSubpath()
        return path
    }
}

// MARK: - Dog-Ear Cutout Shape (for underlying page background)
public struct DogEarCutoutShape: Shape {
    public let size: CGFloat
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - size, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + size))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Marginalia Rail & Dog-Ear Overlay View
public struct MarginaliaOverlayView: View {
    public let bookId: Int
    public let pageNumber: Int
    public let isRightSide: Bool
    public let onAddMarginalia: (Double) -> Void
    
    @ObservedObject private var marginalia = MarginaliaManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    public init(
        bookId: Int,
        pageNumber: Int,
        isRightSide: Bool = true,
        onAddMarginalia: @escaping (Double) -> Void
    ) {
        self.bookId = bookId
        self.pageNumber = pageNumber
        self.isRightSide = isRightSide
        self.onAddMarginalia = onAddMarginalia
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let isFolded = marginalia.isDogEared(bookId: bookId, pageNumber: pageNumber)
            let pageNotes = marginalia.notesFor(bookId: bookId, pageNumber: pageNumber)
            
            ZStack(alignment: .topTrailing) {
                // 1. Dog-Ear Corner Button
                dogEarCornerInteractive(isFolded: isFolded)
                
                // 2. Margin Notes Rail
                VStack(alignment: isRightSide ? .trailing : .leading, spacing: 14) {
                    ForEach(pageNotes) { note in
                        marginaliaNoteBubble(note: note)
                    }
                    
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: isRightSide ? .trailing : .leading)
            }
        }
    }
    
    // MARK: - Interactive Dog-Ear Corner
    private func dogEarCornerInteractive(isFolded: Bool) -> some View {
        Button(action: {
            marginalia.toggleDogEar(bookId: bookId, pageNumber: pageNumber)
        }) {
            ZStack(alignment: .topTrailing) {
                if isFolded {
                    // Crease shadow behind fold
                    DogEarFoldShape(size: 32)
                        .fill(Color.black.opacity(0.18))
                        .offset(x: -1, y: 1)
                        .blur(radius: 2)
                    
                    // Folded flap of the page
                    DogEarFoldShape(size: 32)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(UIColor.secondarySystemGroupedBackground),
                                    Color(UIColor.tertiarySystemGroupedBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            DogEarFoldShape(size: 32)
                                .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                        )
                } else {
                    // Subtle translucent guide inviting dog-ear
                    Image(systemName: "bookmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.secondary.opacity(0.35))
                        .padding(8)
                }
            }
            .frame(width: 44, height: 44, alignment: .topTrailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Marginalia Note Bubble
    private func marginaliaNoteBubble(note: MarginaliaNote) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(note.symbol.rawValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(note.washColor?.color ?? theme.primaryAccent)
            
            Text(note.text)
                .font(.system(size: 10, weight: .medium, design: note.handwritingStyle.fontDesign))
                .italic()
                .foregroundColor(Color(UIColor.label).opacity(0.85))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill((note.washColor?.color ?? theme.primaryAccent).opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke((note.washColor?.color ?? theme.primaryAccent).opacity(0.35), lineWidth: 0.5)
                )
        )
        .frame(maxWidth: 140, alignment: isRightSide ? .trailing : .leading)
    }
}

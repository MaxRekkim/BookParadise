import SwiftUI
import UIKit

public struct BookCoverView: View {
    public let coverURL: URL?
    public let title: String
    public let author: String
    public let genre: Genre
    public var cornerRadius: CGFloat = 8
    
    public init(coverURL: URL?, title: String, author: String = "", genre: Genre = .modernProse, cornerRadius: CGFloat = 8) {
        self.coverURL = coverURL
        self.title = title
        self.author = author
        self.genre = genre
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Group {
            if let url = coverURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            placeholderView
                            ProgressView()
                                .tint(.white)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
    }
    
    private var placeholderView: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [genre.accentColor.opacity(0.85), genre.accentColor.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                let isCompact = geo.size.width < 60
                
                VStack(spacing: isCompact ? 2 : 6) {
                    Image(systemName: genre.iconName)
                        .font(.system(size: isCompact ? 16 : 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if !isCompact {
                        Text(title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 6)
                        
                        if !author.isEmpty {
                            Text(author)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                        }
                    } else {
                        Text(title)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 2)
                    }
                }
                .padding(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

public struct MetricCard: View {
    public let title: String
    public let value: String
    public let subtitle: String
    public let icon: String
    public let color: Color
    public var action: (() -> Void)? = nil
    
    public init(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
    }
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct InteractiveReadingWidgetView: View {
    @State public var widgetState: InteractiveWidgetState
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedAccessory: LockScreenAccessoryStyle = .rectangular
    
    public init(state: InteractiveWidgetState = .sampleActiveState) {
        _widgetState = State(initialValue: state)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Home Screen Interactive Widget Preview
            homeScreenWidgetCard
            
            // Lock Screen Accessory Switcher & Preview
            lockScreenAccessorySection
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("ИНТЕРАКТИВНЫЕ ВИДЖЕТЫ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("IOS 17+ / MACOS")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange))
                }
                
                Text("Логирование в 1 касание")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "hand.tap.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Home Screen Widget Card Preview
    private var homeScreenWidgetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text("\(widgetState.streakDays) ДНЕЙ ПОДРЯД")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    
                    Text(widgetState.bookTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor.label))
                        .lineLimit(1)
                    
                    Text(widgetState.author)
                        .font(.caption2)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                
                Spacer()
                
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(widgetState.progressPercent / 100.0))
                        .stroke(theme.primaryAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text("\(Int(widgetState.progressPercent))%")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(UIColor.label))
                    }
                }
                .frame(width: 44, height: 44)
            }
            
            // Reading Progress Bar
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                        Capsule()
                            .fill(theme.primaryAccent)
                            .frame(width: geo.size.width * CGFloat(widgetState.progressPercent / 100.0))
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(widgetState.currentPage) из \(widgetState.totalPages) стр.")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text("Сегодня: \(widgetState.dailyPagesReadToday)/\(widgetState.dailyQuotaTarget) стр.")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(widgetState.dailyPagesReadToday >= widgetState.dailyQuotaTarget ? .green : Color(UIColor.secondaryLabel))
                }
            }
            
            // 1-Tap Quick Increment Buttons
            HStack(spacing: 8) {
                quickLogButton(delta: 5)
                quickLogButton(delta: 10)
                quickLogButton(delta: 25)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )
        )
    }
    
    private func quickLogButton(delta: Int) -> some View {
        Button(action: {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                widgetState.incrementPages(by: delta)
                AppGroupSyncBridge.saveToAppGroup(widgetState)
            }
        }) {
            HStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                Text("\(delta) стр")
                    .font(.system(size: 11, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(theme.primaryAccent.opacity(0.14))
            )
            .foregroundColor(theme.primaryAccent)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Lock Screen Accessories
    private var lockScreenAccessorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ВИДЖЕТЫ ЭКРАНА БЛОКИРОВКИ")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(UIColor.tertiaryLabel))
            
            // Accessory Style Selector
            Picker("Стиль аксессуара", selection: $selectedAccessory.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
                ForEach(LockScreenAccessoryStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Preview Mock of Lock Screen Accessory
            HStack {
                Spacer()
                switch selectedAccessory {
                case .circular:
                    lockScreenCircularPreview
                case .rectangular:
                    lockScreenRectangularPreview
                case .inline:
                    lockScreenInlinePreview
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var lockScreenCircularPreview: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(widgetState.progressPercent / 100.0))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 1) {
                Image(systemName: "book.fill")
                    .font(.system(size: 12))
                Text("\(Int(widgetState.progressPercent))%")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
            }
            .foregroundColor(.white)
        }
        .frame(width: 60, height: 60)
        .padding(8)
        .background(Circle().fill(Color.black.opacity(0.85)))
    }
    
    private var lockScreenRectangularPreview: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 9))
                Text(widgetState.bookTitle)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
            }
            
            ProgressView(value: widgetState.progressPercent, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
            
            HStack {
                Text("\(widgetState.currentPage)/\(widgetState.totalPages) стр")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                Spacer()
                Text("🔥 \(widgetState.streakDays) дн")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .padding(10)
        .frame(width: 155)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.black.opacity(0.85)))
    }
    
    private var lockScreenInlinePreview: some View {
        HStack(spacing: 4) {
            Image(systemName: "book.fill")
                .font(.system(size: 10))
            Text("«\(widgetState.bookTitle)» — \(widgetState.currentPage) стр. (\(Int(widgetState.progressPercent))%)")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.black.opacity(0.85)))
    }
}

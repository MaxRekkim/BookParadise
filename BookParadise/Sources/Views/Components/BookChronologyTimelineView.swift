import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct BookChronologyTimelineView: View {
    @State public var timeline: BookChronologyTimeline
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    public enum TimelineOrderMode: String, CaseIterable, Identifiable {
        case narrative = "Повествование"
        case chronological = "Хронология мира"
        
        public var id: String { rawValue }
    }
    
    @State private var selectedMode: TimelineOrderMode = .narrative
    @State private var selectedCategory: TimelineEventCategory? = nil
    @State private var expandedEventId: UUID? = nil
    
    public init(timeline: BookChronologyTimeline = .sampleTimeline) {
        _timeline = State(initialValue: timeline)
    }
    
    private var displayedEvents: [TimelineEvent] {
        let baseList: [TimelineEvent]
        switch selectedMode {
        case .narrative:
            baseList = timeline.eventsInNarrativeOrder
        case .chronological:
            baseList = timeline.eventsInChronologicalOrder
        }
        
        if let cat = selectedCategory {
            return baseList.filter { $0.category == cat }
        }
        return baseList
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Picker & Filters
            controlsSection
            
            // Vertical Timeline Spine
            VStack(spacing: 0) {
                ForEach(Array(displayedEvents.enumerated()), id: \.element.id) { index, event in
                    timelineRow(event: event, isLast: index == displayedEvents.count - 1)
                }
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("ХРОНОЛОГИЧЕСКАЯ ОСЬ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    if timeline.flashbackCount > 0 {
                        Text("\(timeline.flashbackCount) ФЛЕШБЭКА")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.purple))
                    }
                }
                
                Text(timeline.bookTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Controls Section
    private var controlsSection: some View {
        VStack(spacing: 10) {
            Picker("Режим шкалы", selection: $selectedMode.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
                ForEach(TimelineOrderMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "Все", isSelected: selectedCategory == nil) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedCategory = nil
                    }
                    
                    ForEach(TimelineEventCategory.allCases, id: \.self) { category in
                        filterChip(
                            title: category.rawValue,
                            icon: category.iconName,
                            isSelected: selectedCategory == category
                        ) {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedCategory = (selectedCategory == category) ? nil : category
                        }
                    }
                }
            }
        }
    }
    
    private func filterChip(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? theme.primaryAccent : Color(UIColor.tertiarySystemGroupedBackground))
            )
            .foregroundColor(isSelected ? .white : Color(UIColor.secondaryLabel))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Timeline Row & Spine Rail
    private func timelineRow(event: TimelineEvent, isLast: Bool) -> some View {
        let isExpanded = expandedEventId == event.id
        
        return HStack(alignment: .top, spacing: 14) {
            // Spine Rail with Node Circle
            VStack(spacing: 0) {
                Circle()
                    .fill(event.category.accentColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color(UIColor.secondarySystemGroupedBackground), lineWidth: 2.5)
                    )
                    .shadow(color: event.category.accentColor.opacity(0.4), radius: 4, x: 0, y: 1)
                
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [event.category.accentColor.opacity(0.6), Color.secondary.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .frame(minHeight: 46)
                }
            }
            .frame(width: 16)
            
            // Event Details Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 6) {
                    Text(event.inWorldEraString)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(event.category.accentColor)
                    
                    Spacer()
                    
                    if event.isFlashback {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 8, weight: .bold))
                            Text("Флешбэк")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.purple.opacity(0.12)))
                    }
                    
                    Text("Гл. \(event.narrativeChapter), с. \(event.narrativePage)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                
                Text(event.eventTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor.label))
                
                if isExpanded || !event.eventDescription.isEmpty {
                    Text(event.eventDescription)
                        .font(.caption)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .lineLimit(isExpanded ? nil : 2)
                        .padding(.top, 1)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.6))
            )
            .contentShape(Rectangle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if expandedEventId == event.id {
                        expandedEventId = nil
                    } else {
                        expandedEventId = event.id
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
    }
}

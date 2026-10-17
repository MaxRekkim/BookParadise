import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct UniversalLibraryImporterView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedFormat: ExternalLibrarySourceFormat = .goodreads
    @State private var importSummary: LibraryImportSummary? = LibraryImportSummary(
        totalProcessed: 48,
        importedBooksCount: 45,
        skippedDuplicatesCount: 3,
        sourceFormat: .goodreads
    )
    @State private var isSimulatingImport: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            // Format Picker
            Picker("Формат библиотеки", selection: $selectedFormat.animation(.spring(response: 0.35, dampingFraction: 0.8))) {
                ForEach(ExternalLibrarySourceFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Import Summary Card
            if let summary = importSummary {
                summaryMetricsCard(summary: summary)
            }
            
            // Upload Trigger Action
            importActionButton
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
                    Text("УНИВЕРСАЛЬНЫЙ ИМПОРТ")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(theme.primaryAccent)
                        .tracking(1.2)
                    
                    Text("GOODREADS & LIVELIB")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue))
                }
                
                Text("Миграция без потери истории")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor.label))
            }
            
            Spacer()
            
            Image(systemName: "square.and.arrow.down.on.square.fill")
                .font(.title2)
                .foregroundColor(theme.primaryAccent)
        }
    }
    
    // MARK: - Summary Card
    private func summaryMetricsCard(summary: LibraryImportSummary) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                metricPill(title: "Обработано", value: "\(summary.totalProcessed)", color: .blue)
                metricPill(title: "Импортировано", value: "\(summary.importedBooksCount)", color: .green)
                metricPill(title: "Дубликаты", value: "\(summary.skippedDuplicatesCount)", color: .orange)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.7))
        )
    }
    
    private func metricPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.opacity(0.08))
        )
    }
    
    // MARK: - Action Button
    private var importActionButton: some View {
        Button(action: {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            isSimulatingImport = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isSimulatingImport = false
                importSummary = LibraryImportSummary(
                    totalProcessed: 52,
                    importedBooksCount: 49,
                    skippedDuplicatesCount: 3,
                    sourceFormat: selectedFormat
                )
            }
        }) {
            HStack(spacing: 6) {
                if isSimulatingImport {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 11, weight: .bold))
                }
                
                Text(isSimulatingImport ? "Анализ структуры файла..." : "Выбрать файл \(selectedFormat.rawValue)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.primaryAccent)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .disabled(isSimulatingImport)
    }
}

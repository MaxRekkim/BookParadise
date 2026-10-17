import SwiftUI

/// Мастерская персонального книжного знака (Ex Libris Studio Sheet)
/// Позволяет читателю настроить личный экслибрис, выбрать геральдический стиль, девиз и тип тиснения.
public struct ExLibrisStudioSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var config: ExLibrisConfig = ExLibrisConfig.load()
    @State private var showSavedToast: Bool = false
    @State private var showingExportShare: Bool = false

    private let wineAccent = Color(red: 0.52, green: 0.14, blue: 0.20)

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Интерактивный предпросмотр книжного знака
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.95))
                            .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)

                        PaperNoiseOverlay()
                            .opacity(0.04)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(spacing: 8) {
                            Text("ПРЕДПРОСМОТР ФОРЗАЦА КНИГИ")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(2.0)
                                .foregroundColor(.secondary)
                                .padding(.top, 16)

                            ExLibrisBookplateView(config: config, scale: 1.15)
                                .padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Форма настройки параметров
                    VStack(spacing: 20) {
                        // 1. Персональные данные владельца
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ДАННЫЕ ВЛАДЕЛЬЦА")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Имя:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Имя владельца", text: $config.ownerName)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Text("Монограмма:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Инициалы", text: $config.monogram)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // 2. Девиз библиофила
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ДЕВИЗ БИБЛИОТЕКИ")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 10) {
                                TextField("Девиз на латыни или русском", text: $config.motto)
                                    .textFieldStyle(.roundedBorder)

                                Text("Классические девизы:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(ExLibrisConfig.suggestedMottos, id: \.self) { motto in
                                            Button {
                                                config.motto = motto
                                                HapticManager.shared.lightTap()
                                            } label: {
                                                Text(motto)
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(config.motto == motto ? wineAccent : Color(.tertiarySystemFill))
                                                    .foregroundColor(config.motto == motto ? .white : .primary)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // 3. Художественный стиль
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ГРАФИЧЕСКИЙ СТИЛЬ")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            VStack(spacing: 8) {
                                ForEach(ExLibrisStyle.allCases) { style in
                                    Button {
                                        config.style = style
                                        HapticManager.shared.lightTap()
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: style.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(config.style == style ? wineAccent : .secondary)
                                                .frame(width: 24)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(style.title)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(.primary)
                                                Text(style.subtitle)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            if config.style == style {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(wineAccent)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(config.style == style ? wineAccent.opacity(0.08) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    if style != ExLibrisStyle.allCases.last {
                                        Divider()
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // 4. Тип тиснения и материала
                        VStack(alignment: .leading, spacing: 12) {
                            Text("МАТЕРИАЛИЗАЦИЯ И ТИСНЕНИЕ")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)

                            Picker("Тиснение", selection: $config.embossType) {
                                ForEach(ExLibrisEmbossType.allCases) { emboss in
                                    Text(emboss.title).tag(emboss)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // 5. Опция автоматического штампа на форзацах
                        Toggle(isOn: $config.isAutoStampEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Штамповать форзацы всех книг")
                                    .font(.subheadline.weight(.semibold))
                                Text("Экслибрис будет выгравирован на первой странице при открытии книг")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(wineAccent)
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    // Кнопка сохранения
                    Button {
                        config.save()
                        HapticManager.shared.mediumTap()
                        withAnimation {
                            showSavedToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showSavedToast = false
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "seal.fill")
                            Text("Сохранить экслибрис в библиотеку")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(wineAccent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Мастерская экслибриса")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        config.save()
                        dismiss()
                    }
                    .foregroundColor(wineAccent)
                    .fontWeight(.bold)
                }
            }
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Экслибрис успешно сохранён и нанесён на книги!")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 8)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

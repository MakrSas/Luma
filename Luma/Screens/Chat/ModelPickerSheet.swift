import SwiftUI

struct ModelPickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            List {
                ForEach(appState.availableModels.filter { $0.downloadState == .installed }) { model in
                    Button {
                        appState.selectedModelID = model.id
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(LumaType.subheadline.weight(.semibold))
                                    .foregroundStyle(LumaColor.textPrimary)
                                Text("\(model.parameterCount) · \(model.quantization) · \(String(format: "%.1f", model.estimatedRAMUsageGB)) ГБ ОЗУ")
                                    .font(LumaType.caption)
                                    .foregroundStyle(LumaColor.textSecondary)
                            }
                            Spacer()
                            if model.id == appState.selectedModelID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(LumaColor.accent)
                            }
                        }
                    }
                }
                if appState.availableModels.allSatisfy({ $0.downloadState != .installed }) {
                    Text("Нет скачанных моделей")
                        .foregroundStyle(LumaColor.textSecondary)
                }
            }
            .navigationTitle("Модель")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationBackground(.thinMaterial)
    }
}

struct IntelligencePickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            VStack(spacing: LumaSpacing.sm) {
                ForEach(IntelligenceMode.allCases) { mode in
                    Button {
                        appState.intelligenceMode = mode
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: LumaSpacing.sm) {
                            Image(systemName: mode.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(LumaColor.accent)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(LumaType.subheadline.weight(.semibold))
                                    .foregroundStyle(LumaColor.textPrimary)
                                Text(mode.shortDescription)
                                    .font(LumaType.caption)
                                    .foregroundStyle(LumaColor.textSecondary)
                            }
                            Spacer()
                            if mode == appState.intelligenceMode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LumaColor.accent)
                            }
                        }
                        .padding(LumaSpacing.sm)
                        .glassSurface(cornerRadius: LumaRadius.medium, tint: mode == appState.intelligenceMode ? LumaColor.accent.opacity(0.12) : nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(LumaSpacing.md)
            .navigationTitle("Режим интеллекта")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationBackground(.thinMaterial)
    }
}

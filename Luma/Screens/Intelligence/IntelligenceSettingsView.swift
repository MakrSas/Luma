import SwiftUI

struct IntelligenceSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: LumaSpacing.lg) {
                Text("Режим интеллекта управляет тем, сколько планирования и проверок агент делает перед ответом.")
                    .font(LumaType.subheadline)
                    .foregroundStyle(LumaColor.textSecondary)

                VStack(spacing: LumaSpacing.sm) {
                    ForEach(IntelligenceMode.allCases) { mode in
                        modeCard(mode)
                    }
                }

                if appState.intelligenceMode == .auto {
                    autoRulesSection
                }
            }
            .padding(LumaSpacing.md)
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Настройки интеллекта")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func modeCard(_ mode: IntelligenceMode) -> some View {
        let isSelected = mode == appState.intelligenceMode
        return Button {
            appState.intelligenceMode = mode
        } label: {
            VStack(alignment: .leading, spacing: LumaSpacing.xs) {
                HStack {
                    Image(systemName: mode.systemImage)
                        .foregroundStyle(LumaColor.accent)
                    Text(mode.title)
                        .font(LumaType.headline)
                        .foregroundStyle(LumaColor.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LumaColor.accent)
                    }
                }
                Text(mode.shortDescription)
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(mode.detailPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: LumaSpacing.xxs) {
                            Text("–")
                            Text(point)
                        }
                        .font(LumaType.caption)
                        .foregroundStyle(LumaColor.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LumaSpacing.sm)
            .glassSurface(tint: isSelected ? LumaColor.accent.opacity(0.12) : nil)
        }
        .buttonStyle(.plain)
    }

    private var autoRulesSection: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.xs) {
            Text("Формат оценки сложности")
                .font(LumaType.headline)
                .foregroundStyle(LumaColor.textPrimary)
            Text("difficulty, confidence, estimatedToolCalls, needsPlanning, needsClarification, containsCode, containsFiles, riskLevel")
                .font(LumaType.monospaceCaption)
                .foregroundStyle(LumaColor.textSecondary)
        }
        .padding(LumaSpacing.sm)
        .glassSurface()
    }
}

#Preview {
    NavigationStack {
        IntelligenceSettingsView()
    }
    .environment(AppState())
}

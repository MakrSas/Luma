import SwiftUI

struct PerformanceSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: LumaSpacing.md) {
                Text("Профиль производительности влияет на размер контекста, KV-кэш и частоту повторных проверок агента.")
                    .font(LumaType.subheadline)
                    .foregroundStyle(LumaColor.textSecondary)

                ForEach(PerformanceProfile.allCases) { profile in
                    let isSelected = profile == appState.performanceProfile
                    Button {
                        appState.performanceProfile = profile
                    } label: {
                        HStack(alignment: .top, spacing: LumaSpacing.sm) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.title)
                                    .font(LumaType.headline)
                                    .foregroundStyle(LumaColor.textPrimary)
                                Text(profile.detail)
                                    .font(LumaType.footnote)
                                    .foregroundStyle(LumaColor.textSecondary)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LumaColor.accent)
                            }
                        }
                        .padding(LumaSpacing.sm)
                        .glassSurface(tint: isSelected ? LumaColor.accent.opacity(0.12) : nil)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: LumaSpacing.xs) {
                    Text("Память устройства")
                        .font(LumaType.headline)
                        .foregroundStyle(LumaColor.textPrimary)
                    Text("Luma оптимизирована для iPhone с 6 ГБ ОЗУ: в памяти держится только одна активная модель, а размер KV-кэша ограничен профилем производительности.")
                        .font(LumaType.footnote)
                        .foregroundStyle(LumaColor.textSecondary)
                }
                .padding(LumaSpacing.sm)
                .glassSurface()
            }
            .padding(LumaSpacing.md)
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Производительность")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PerformanceSettingsView()
    }
    .environment(AppState())
}

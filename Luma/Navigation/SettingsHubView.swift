import SwiftUI

/// Layout modeled directly on Apple's own Settings app (grouped rounded
/// sections, square icon badges, trailing chevron) — per CLAUDE.md/DESIGN.md
/// the icon badges stay one neutral monochrome tone rather than Apple's own
/// per-row accent colors (Wi-Fi blue, Cellular green, etc).
struct SettingsHubView: View {
    @Binding var path: NavigationPath

    var body: some View {
        List {
            Section("Модель и интеллект") {
                row(icon: "square.stack.3d.up.fill", title: "Каталог моделей", route: .modelCatalog)
                row(icon: "wand.and.sparkles", title: "Настройки интеллекта", route: .intelligenceSettings)
                row(icon: "gauge.with.needle.fill", title: "Производительность", route: .performanceSettings)
            }
            Section("Данные и безопасность") {
                row(icon: "hand.raised.fill", title: "Центр разрешений", route: .permissionsCenter)
                row(icon: "brain.head.profile", title: "Долговременная память", route: .memory)
                row(icon: "list.bullet.clipboard.fill", title: "Журнал действий", route: .actionLog)
            }
            Section("Персонализация") {
                row(icon: "app.badge.fill", title: "Значок приложения", route: .appIconPicker)
            }
            Section("О приложении") {
                row(icon: "stethoscope", title: "Диагностика", route: .diagnostics)
                row(icon: "doc.text.fill", title: "Лицензии моделей", route: .licenses)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Настройки")
    }

    private func row(icon: String, title: String, route: Route) -> some View {
        Button {
            path.append(route)
        } label: {
            HStack(spacing: LumaSpacing.sm) {
                iconBadge(icon)
                Text(title)
                    .font(LumaType.body)
                    .foregroundStyle(LumaColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LumaColor.textTertiary)
            }
        }
        .padding(.vertical, LumaSpacing.xxs)
    }

    private func iconBadge(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(LumaColor.onAccent)
            .frame(width: 29, height: 29)
            .background(LumaColor.accent, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        SettingsHubView(path: .constant(NavigationPath()))
    }
    .environment(AppState())
}

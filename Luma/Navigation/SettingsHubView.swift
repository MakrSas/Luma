import SwiftUI

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
            Section("О приложении") {
                row(icon: "stethoscope", title: "Диагностика", route: .diagnostics)
                row(icon: "doc.text.fill", title: "Лицензии моделей", route: .licenses)
            }
        }
        .navigationTitle("Настройки")
    }

    private func row(icon: String, title: String, route: Route) -> some View {
        Button {
            path.append(route)
        } label: {
            Label(title, systemImage: icon)
                .foregroundStyle(LumaColor.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsHubView(path: .constant(NavigationPath()))
    }
    .environment(AppState())
}

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HistoryView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
        .tint(LumaColor.accent)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .conversation(let id):
            ChatView(path: $path, conversationID: id)
        case .settingsHub:
            SettingsHubView(path: $path)
        case .modelCatalog:
            ModelCatalogView(path: $path)
        case .modelDetail(let id):
            ModelDetailView(modelID: id, path: $path)
        case .modelDownload(let id):
            ModelDownloadView(modelID: id)
        case .intelligenceSettings:
            IntelligenceSettingsView()
        case .appIconPicker:
            AppIconPickerView()
        case .permissionsCenter:
            PermissionsCenterView()
        case .memory:
            MemoryView(path: $path)
        case .memoryEditor(let id):
            MemoryEditorView(recordID: id)
        case .actionLog:
            ActionLogView()
        case .performanceSettings:
            PerformanceSettingsView()
        case .diagnostics:
            DiagnosticsView()
        case .licenses:
            LicensesView()
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
}

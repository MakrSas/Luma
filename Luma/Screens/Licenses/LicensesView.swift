import SwiftUI

struct LicensesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            Section {
                Text("Каждая локальная модель распространяется по собственной лицензии разработчика. Скачивая модель, вы принимаете её условия.")
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
            }
            ForEach(appState.availableModels) { model in
                Section(model.name) {
                    row("Разработчик", model.developer)
                    row("Лицензия", model.license)
                }
            }
        }
        .navigationTitle("Лицензии моделей")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(LumaColor.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(LumaColor.textPrimary)
        }
        .font(LumaType.footnote)
    }
}

#Preview {
    NavigationStack {
        LicensesView()
    }
    .environment(AppState())
}

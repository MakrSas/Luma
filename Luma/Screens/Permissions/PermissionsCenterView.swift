import SwiftUI

struct PermissionsCenterView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        List {
            Section {
                Text("Разрешения управляют тем, что агенту разрешено делать без вопросов, что требует подтверждения, и что запрещено полностью.")
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
            }
            ForEach($appState.permissions) { $permission in
                Section {
                    VStack(alignment: .leading, spacing: LumaSpacing.xs) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(permission.displayName)
                                    .font(LumaType.subheadline.weight(.semibold))
                                    .foregroundStyle(LumaColor.textPrimary)
                                Text(permission.toolDescription)
                                    .font(LumaType.caption)
                                    .foregroundStyle(LumaColor.textSecondary)
                            }
                            Spacer()
                            Text(permission.riskLevel.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(LumaColor.risk(permission.riskLevel))
                        }

                        Picker("Уровень доступа", selection: $permission.state) {
                            ForEach(PermissionState.allCases) { state in
                                Text(state.label).tag(state)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let systemPermission = permission.requiresSystemPermission {
                            Label("Требует системное разрешение: \(systemPermission)", systemImage: "lock.shield")
                                .font(LumaType.caption)
                                .foregroundStyle(LumaColor.textTertiary)
                        }
                    }
                    .padding(.vertical, LumaSpacing.xxs)
                }
            }
        }
        .navigationTitle("Центр разрешений")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PermissionsCenterView()
    }
    .environment(AppState())
}

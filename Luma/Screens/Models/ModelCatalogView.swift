import SwiftUI

struct ModelCatalogView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            LazyVStack(spacing: LumaSpacing.sm) {
                ForEach(appState.availableModels) { model in
                    Button {
                        path.append(Route.modelDetail(model.id))
                    } label: {
                        ModelCatalogRow(model: model)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(LumaSpacing.md)
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Каталог моделей")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ModelCatalogView(path: .constant(NavigationPath()))
    }
    .environment(AppState())
}

struct ModelCatalogRow: View {
    var model: LocalModel

    var body: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.xs) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: LumaSpacing.xxs) {
                        Text(model.name)
                            .font(LumaType.headline)
                            .foregroundStyle(LumaColor.textPrimary)
                        if model.isRecommended {
                            Text("Рекомендуется")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .foregroundStyle(LumaColor.onAccent)
                                .background(LumaColor.accent, in: Capsule())
                        }
                    }
                    Text("\(model.developer) · \(model.family)")
                        .font(LumaType.caption)
                        .foregroundStyle(LumaColor.textSecondary)
                }
                Spacer()
                statusBadge
            }

            Text(model.summary)
                .font(LumaType.footnote)
                .foregroundStyle(LumaColor.textSecondary)
                .lineLimit(2)

            HStack(spacing: LumaSpacing.sm) {
                metric("Параметры", model.parameterCount)
                metric("Квант.", model.quantization)
                metric("Размер", String(format: "%.1f ГБ", model.downloadSizeGB))
                metric("ОЗУ", String(format: "%.1f ГБ", model.estimatedRAMUsageGB))
            }

            if !model.isCompatibleWithDevice {
                Label("Несовместимо с этим iPhone", systemImage: "exclamationmark.triangle.fill")
                    .font(LumaType.caption)
                    .foregroundStyle(LumaColor.danger)
            }
        }
        .padding(LumaSpacing.sm)
        .background(LumaColor.canvasElevated, in: RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous)
                .strokeBorder(LumaColor.separator.opacity(0.6), lineWidth: 0.5)
        )
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(LumaType.caption.weight(.semibold))
                .foregroundStyle(LumaColor.textPrimary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(LumaColor.textTertiary)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch model.downloadState {
        case .installed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(LumaColor.success)
        case .downloading(let progress):
            ProgressView(value: progress)
                .progressViewStyle(.circular)
                .controlSize(.small)
        case .verifying:
            ProgressView()
                .controlSize(.small)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(LumaColor.danger)
        case .notDownloaded:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(LumaColor.textTertiary)
        }
    }
}

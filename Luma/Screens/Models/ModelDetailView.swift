import SwiftUI

struct ModelDetailView: View {
    @Environment(AppState.self) private var appState
    var modelID: String
    @Binding var path: NavigationPath

    private var model: LocalModel? {
        appState.availableModels.first(where: { $0.id == modelID })
    }

    var body: some View {
        if let model {
            ScrollView {
                VStack(alignment: .leading, spacing: LumaSpacing.lg) {
                    VStack(alignment: .leading, spacing: LumaSpacing.xxs) {
                        Text(model.name)
                            .font(LumaType.display(28))
                            .foregroundStyle(LumaColor.textPrimary)
                        Text("\(model.developer) · \(model.family)")
                            .font(LumaType.subheadline)
                            .foregroundStyle(LumaColor.textSecondary)
                    }

                    Text(model.summary)
                        .font(LumaType.body)
                        .foregroundStyle(LumaColor.textPrimary)

                    qualitySection
                    specSection

                    if !model.isCompatibleWithDevice {
                        Label("Эта модель несовместима с текущим устройством по объёму памяти", systemImage: "exclamationmark.triangle.fill")
                            .font(LumaType.footnote)
                            .foregroundStyle(LumaColor.danger)
                            .padding(LumaSpacing.sm)
                            .glassSurface(tint: LumaColor.danger.opacity(0.12))
                    }

                    actionButton
                }
                .padding(LumaSpacing.md)
            }
            .background(LumaColor.canvas.ignoresSafeArea())
            .navigationTitle("Модель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(Route.licenses)
                    } label: {
                        Image(systemName: "doc.text")
                    }
                }
            }
        } else {
            ContentUnavailableView("Модель не найдена", systemImage: "questionmark.square.dashed")
        }
    }

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.xs) {
            Text("Качество")
                .font(LumaType.headline)
                .foregroundStyle(LumaColor.textPrimary)
            qualityBar("Русский язык", model!.russianQuality)
            qualityBar("Код", model!.codeQuality)
            qualityBar("Вызов инструментов", model!.toolCallingQuality)
            qualityBar("Рассуждения", model!.reasoningQuality)
            qualityBar("Скорость", model!.speed)
            qualityBar("Общая оценка", model!.overallScore)
        }
        .padding(LumaSpacing.sm)
        .glassSurface()
    }

    private func qualityBar(_ label: String, _ value: Int) -> some View {
        HStack {
            Text(label)
                .font(LumaType.footnote)
                .foregroundStyle(LumaColor.textSecondary)
                .frame(width: 150, alignment: .leading)
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(i < value ? LumaColor.accent : LumaColor.separator)
                        .frame(width: 16, height: 5)
                }
            }
        }
    }

    private var specSection: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.xs) {
            Text("Характеристики")
                .font(LumaType.headline)
                .foregroundStyle(LumaColor.textPrimary)
            specRow("Параметры", model!.parameterCount)
            specRow("Квантование", model!.quantization)
            specRow("Размер загрузки", String(format: "%.1f ГБ", model!.downloadSizeGB))
            specRow("Расход ОЗУ", String(format: "≈ %.1f ГБ", model!.estimatedRAMUsageGB))
            specRow("Лицензия", model!.license)
            specRow("Совместимость", model!.isCompatibleWithDevice ? "Совместима с этим iPhone" : "Несовместима")
        }
        .padding(LumaSpacing.sm)
        .glassSurface()
    }

    private func specRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(LumaType.footnote)
                .foregroundStyle(LumaColor.textSecondary)
            Spacer()
            Text(value)
                .font(LumaType.footnote.weight(.medium))
                .foregroundStyle(LumaColor.textPrimary)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch model!.downloadState {
        case .notDownloaded:
            Button {
                path.append(Route.modelDownload(model!.id))
            } label: {
                Label("Скачать · \(String(format: "%.1f", model!.downloadSizeGB)) ГБ", systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(LumaColor.onAccent)
                    .frame(maxWidth: .infinity)
            }
            .lumaGlassProminentButtonStyle()
            .disabled(!model!.isCompatibleWithDevice)
        case .downloading, .verifying:
            Button {
                path.append(Route.modelDownload(model!.id))
            } label: {
                Label("Показать загрузку", systemImage: "arrow.down.circle")
                    .frame(maxWidth: .infinity)
            }
            .lumaGlassButtonStyle()
        case .installed:
            Button(role: .destructive) {
                deleteModel()
            } label: {
                Label("Удалить модель", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .lumaGlassButtonStyle()
        case .failed:
            Button {
                path.append(Route.modelDownload(model!.id))
            } label: {
                Label("Повторить загрузку", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .lumaGlassProminentButtonStyle()
        }
    }

    private func deleteModel() {
        guard let idx = appState.availableModels.firstIndex(where: { $0.id == modelID }) else { return }
        ModelDownloader.delete(appState.availableModels[idx])
        appState.availableModels[idx].downloadState = .notDownloaded
        if appState.selectedModelID == modelID {
            appState.selectedModelID = appState.availableModels.first(where: { $0.downloadState == .installed })?.id
                ?? appState.availableModels[0].id
        }
    }
}

#Preview {
    NavigationStack {
        ModelDetailView(modelID: LocalModel.mockCatalog[0].id, path: .constant(NavigationPath()))
    }
    .environment(AppState())
}

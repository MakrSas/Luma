import SwiftUI

struct ModelDownloadView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    var modelID: String

    private enum Phase: Equatable {
        case downloading
        case verifying
        case done
        case failed(String)
    }

    @State private var progress: Double = 0
    @State private var phase: Phase = .downloading
    @State private var downloadTask: Task<Void, Never>?

    private var model: LocalModel? {
        appState.availableModels.first(where: { $0.id == modelID })
    }

    var body: some View {
        VStack(spacing: LumaSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(LumaColor.separator, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(LumaColor.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)
                Text("\(Int(progress * 100))%")
                    .font(LumaType.title)
                    .foregroundStyle(LumaColor.textPrimary)
            }
            .frame(width: 160, height: 160)

            VStack(spacing: LumaSpacing.xxs) {
                Text(model?.name ?? "Модель")
                    .font(LumaType.headline)
                    .foregroundStyle(LumaColor.textPrimary)
                Text(statusText)
                    .font(LumaType.footnote)
                    .foregroundStyle(isFailed ? LumaColor.danger : LumaColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: LumaSpacing.xs) {
                checklistRow("Загрузка файлов с HuggingFace", done: progress >= 1 || phase == .verifying || phase == .done, active: phase == .downloading)
                checklistRow("Проверка SHA-256", done: phase == .done, active: phase == .verifying)
            }
            .padding(LumaSpacing.sm)
            .glassSurface()

            Spacer()

            Button(role: .destructive) {
                cancel()
            } label: {
                Label(phase == .done ? "Готово" : "Отменить", systemImage: phase == .done ? "checkmark" : "xmark")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LumaSpacing.xxs)
            }
            .lumaGlassButtonStyle()
            .controlSize(.large)
            .padding(.bottom, LumaSpacing.sm)
        }
        .padding(.horizontal, LumaSpacing.md)
        .padding(.top, LumaSpacing.md)
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Загрузка модели")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: startDownload)
        .onDisappear { downloadTask?.cancel() }
    }

    private var isFailed: Bool {
        if case .failed = phase { return true }
        return false
    }

    private var statusText: String {
        switch phase {
        case .downloading: return "Загрузка файлов модели…"
        case .verifying: return "Проверка целостности…"
        case .done: return "Готово к использованию"
        case .failed(let reason): return "Ошибка: \(reason)"
        }
    }

    private func checklistRow(_ text: String, done: Bool, active: Bool = false) -> some View {
        HStack(spacing: LumaSpacing.xs) {
            Image(systemName: done ? "checkmark.circle.fill" : (active ? "circle.dotted" : "circle"))
                .foregroundStyle(done ? LumaColor.success : LumaColor.textTertiary)
            Text(text)
                .font(LumaType.footnote)
                .foregroundStyle(done ? LumaColor.textPrimary : LumaColor.textSecondary)
        }
    }

    private func startDownload() {
        guard let model, downloadTask == nil else { return }
        if let idx = appState.availableModels.firstIndex(where: { $0.id == modelID }) {
            appState.availableModels[idx].downloadState = .downloading(progress: 0)
        }

        downloadTask = Task {
            do {
                try await ModelDownloader.download(model) { fraction in
                    Task { @MainActor in
                        progress = fraction
                        if let idx = appState.availableModels.firstIndex(where: { $0.id == modelID }) {
                            appState.availableModels[idx].downloadState = .downloading(progress: fraction)
                        }
                    }
                }
                await MainActor.run {
                    phase = .verifying
                }
                await MainActor.run {
                    phase = .done
                    progress = 1
                    if let idx = appState.availableModels.firstIndex(where: { $0.id == modelID }) {
                        appState.availableModels[idx].downloadState = .installed
                    }
                    appState.selectedModelID = modelID
                }
            } catch is CancellationError {
                if let idx = appState.availableModels.firstIndex(where: { $0.id == modelID }) {
                    appState.availableModels[idx].downloadState = .notDownloaded
                }
            } catch {
                await MainActor.run {
                    phase = .failed(error.localizedDescription)
                    if let idx = appState.availableModels.firstIndex(where: { $0.id == modelID }) {
                        appState.availableModels[idx].downloadState = .failed(reason: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func cancel() {
        if phase == .done {
            dismiss()
            return
        }
        downloadTask?.cancel()
        downloadTask = nil
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ModelDownloadView(modelID: LocalModel.mockCatalog[1].id)
    }
    .environment(AppState())
}

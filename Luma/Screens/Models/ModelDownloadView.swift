import SwiftUI

struct ModelDownloadView: View {
    @Environment(AppState.self) private var appState
    var modelID: String
    @State private var progress: Double = 0.18
    @State private var isPaused = false
    @State private var timer: Timer?

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
                    .foregroundStyle(LumaColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: LumaSpacing.xs) {
                checklistRow("Проверка свободного места", done: true)
                checklistRow("Загрузка файла", done: progress > 0.05, active: !isPaused && progress < 1)
                checklistRow("Проверка SHA-256", done: progress >= 1)
                checklistRow("Проверка совместимости runtime", done: progress >= 1)
            }
            .padding(LumaSpacing.sm)
            .glassSurface()

            Spacer()

            HStack(spacing: LumaSpacing.sm) {
                Button {
                    isPaused.toggle()
                } label: {
                    Label(isPaused ? "Продолжить" : "Пауза", systemImage: isPaused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }
                .lumaGlassButtonStyle()

                Button(role: .destructive) {
                    stopTimer()
                    progress = 0
                } label: {
                    Label("Отменить", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .lumaGlassButtonStyle()
            }
        }
        .padding(LumaSpacing.md)
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Загрузка модели")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }

    private var statusText: String {
        if progress >= 1 { return "Готово к использованию" }
        if isPaused { return "Загрузка приостановлена" }
        return "Загрузка и проверка целостности файла…"
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

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            guard !isPaused, progress < 1 else { return }
            progress = min(1, progress + 0.05)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        ModelDownloadView(modelID: LocalModel.mockCatalog[2].id)
    }
    .environment(AppState())
}

import SwiftUI

struct DiagnosticsView: View {
    @State private var snapshot = DiagnosticsSnapshot()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LumaSpacing.md) {
                group("Устройство") {
                    row("Модель", snapshot.deviceModel)
                    row("Чип", snapshot.chip)
                    row("Оперативная память", "\(String(format: "%.1f", snapshot.totalRAMGB)) ГБ")
                    row("Доступно сейчас", "\(String(format: "%.1f", snapshot.availableRAMGB)) ГБ")
                    row("Свободное место", "\(String(format: "%.1f", snapshot.storageAvailableGB)) ГБ")
                    row("Тепловое состояние", snapshot.thermalState)
                }
                group("Активная модель") {
                    row("Модель", snapshot.activeModelName)
                    row("Контекст", "\(snapshot.contextWindowUsed) / \(snapshot.contextWindowTotal) токенов")
                    row("Скорость генерации", "\(String(format: "%.1f", snapshot.lastTokenSpeed)) ток/с")
                    row("Время до первого токена", "\(snapshot.lastTimeToFirstTokenMs) мс")
                }
                Text("В Этапе 1 показаны демонстрационные значения. Реальный сбор диагностики появится вместе с локальной моделью.")
                    .font(LumaType.caption)
                    .foregroundStyle(LumaColor.textTertiary)
            }
            .padding(LumaSpacing.md)
        }
        .background(LumaColor.canvas.ignoresSafeArea())
        .navigationTitle("Диагностика")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: LumaSpacing.xs) {
            Text(title)
                .font(LumaType.headline)
                .foregroundStyle(LumaColor.textPrimary)
            VStack(spacing: LumaSpacing.xxs) {
                content()
            }
        }
        .padding(LumaSpacing.sm)
        .glassSurface()
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(LumaType.footnote)
                .foregroundStyle(LumaColor.textSecondary)
            Spacer()
            Text(value)
                .font(LumaType.monospaceCaption)
                .foregroundStyle(LumaColor.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        DiagnosticsView()
    }
}

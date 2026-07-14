import SwiftUI

/// Confirmation prompt shown before risky tool calls (deletion, sending data,
/// modifying existing records, unknown URLs, etc). Stage 1: static mock UI.
struct ConfirmationCardView: View {
    var title: String
    var toolName: String
    var whatWillHappen: String
    var dataUsed: String
    var isReversible: Bool
    var riskLevel: RiskLevel
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LumaSpacing.sm) {
            HStack(spacing: LumaSpacing.xs) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(LumaColor.risk(riskLevel))
                Text(title)
                    .font(LumaType.headline)
                    .foregroundStyle(LumaColor.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: LumaSpacing.xxs) {
                infoRow(label: "Инструмент", value: toolName)
                infoRow(label: "Что произойдёт", value: whatWillHappen)
                infoRow(label: "Используемые данные", value: dataUsed)
                infoRow(label: "Отмена", value: isReversible ? "Действие можно отменить" : "Действие необратимо")
            }

            HStack(spacing: LumaSpacing.sm) {
                Button("Отменить", role: .cancel, action: onCancel)
                    .lumaGlassButtonStyle()
                Button {
                    onConfirm()
                } label: {
                    Text("Подтвердить")
                        .foregroundStyle(LumaColor.onAccent)
                }
                .lumaGlassProminentButtonStyle()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(LumaSpacing.md)
        .glassSurface(cornerRadius: LumaRadius.large, tint: LumaColor.risk(riskLevel).opacity(0.12))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: LumaSpacing.xs) {
            Text(label)
                .font(LumaType.caption)
                .foregroundStyle(LumaColor.textTertiary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(LumaType.footnote)
                .foregroundStyle(LumaColor.textPrimary)
        }
    }
}

#Preview {
    ConfirmationCardView(
        title: "Подтвердите действие",
        toolName: "update_calendar_event",
        whatWillHappen: "Событие «Встреча с врачом» будет перенесено на пятницу, 10:00",
        dataUsed: "Событие календаря от 14 июля",
        isReversible: true,
        riskLevel: .medium,
        onConfirm: {},
        onCancel: {}
    )
    .padding()
    .background(LumaColor.canvas)
}

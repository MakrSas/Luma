import SwiftUI

struct ToolActionCardView: View {
    var action: ToolActionCard

    var body: some View {
        HStack(alignment: .top, spacing: LumaSpacing.sm) {
            Image(systemName: statusIcon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.displayTitle)
                    .font(LumaType.subheadline.weight(.semibold))
                    .foregroundStyle(LumaColor.textPrimary)
                Text(action.detail)
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
                Text(action.toolName)
                    .font(LumaType.monospaceCaption)
                    .foregroundStyle(LumaColor.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(LumaSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaColor.canvasElevated, in: RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
    }

    private var statusIcon: String {
        switch action.status {
        case .pending: return "clock"
        case .awaitingConfirmation: return "questionmark.circle.fill"
        case .running: return "gearshape.2.fill"
        case .succeeded: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch action.status {
        case .succeeded: return LumaColor.success
        case .failed: return LumaColor.danger
        case .cancelled: return LumaColor.textTertiary
        case .awaitingConfirmation: return LumaColor.warning
        case .pending, .running: return LumaColor.accent
        }
    }
}

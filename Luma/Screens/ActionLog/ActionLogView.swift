import SwiftUI

struct ActionLogView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(appState.actionLog.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                VStack(alignment: .leading, spacing: LumaSpacing.xxs) {
                    HStack {
                        Text(entry.displayTitle)
                            .font(LumaType.subheadline.weight(.semibold))
                            .foregroundStyle(LumaColor.textPrimary)
                        Spacer()
                        outcomeLabel(entry.outcome)
                    }
                    Text(entry.detail)
                        .font(LumaType.footnote)
                        .foregroundStyle(LumaColor.textSecondary)
                    HStack(spacing: LumaSpacing.xxs) {
                        Text(entry.toolName)
                            .font(LumaType.monospaceCaption)
                            .foregroundStyle(LumaColor.textTertiary)
                        Text("·")
                            .foregroundStyle(LumaColor.textTertiary)
                        Text(entry.conversationTitle)
                            .font(LumaType.caption)
                            .foregroundStyle(LumaColor.textTertiary)
                        Spacer()
                        Text(entry.timestamp, format: .relative(presentation: .named))
                            .font(LumaType.caption)
                            .foregroundStyle(LumaColor.textTertiary)
                    }
                }
                .padding(.vertical, LumaSpacing.xxs)
            }
        }
        .navigationTitle("Журнал действий")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func outcomeLabel(_ outcome: ActionLogEntry.Outcome) -> some View {
        Text(outcome.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color(for: outcome))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color(for: outcome).opacity(0.14), in: Capsule())
    }

    private func color(for outcome: ActionLogEntry.Outcome) -> Color {
        switch outcome {
        case .succeeded, .confirmed: return LumaColor.success
        case .failed: return LumaColor.danger
        case .cancelled, .denied: return LumaColor.textTertiary
        }
    }
}

#Preview {
    NavigationStack {
        ActionLogView()
    }
    .environment(AppState())
}

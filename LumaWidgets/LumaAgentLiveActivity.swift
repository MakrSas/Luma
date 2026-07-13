import ActivityKit
import WidgetKit
import SwiftUI

struct LumaAgentLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LumaAgentActivityAttributes.self) { context in
            LockScreenLiveActivityView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(LumaColor.canvasElevated)
                .widgetURL(URL(string: "luma://conversation/\(context.state.conversationID.uuidString)"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.phase.systemImage)
                        .foregroundStyle(LumaColor.accent)
                        .font(.system(size: 18, weight: .semibold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase != .completed && context.state.phase != .failed {
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(.circular)
                            .tint(LumaColor.accent)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.conversationTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.phase.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        if !context.state.previewText.isEmpty {
                            Text(context.state.previewText)
                                .font(.system(size: 13))
                                .lineLimit(2)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phase.systemImage)
                    .foregroundStyle(LumaColor.accent)
            } compactTrailing: {
                Text(context.state.phase.label)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            } minimal: {
                Image(systemName: context.state.phase.systemImage)
                    .foregroundStyle(LumaColor.accent)
            }
        }
    }
}

private struct LockScreenLiveActivityView: View {
    var attributes: LumaAgentActivityAttributes
    var state: LumaAgentActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.phase.systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(LumaColor.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(attributes.conversationTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(state.phase.label + (state.toolName.map { " · \($0)" } ?? ""))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                if !state.previewText.isEmpty {
                    Text(state.previewText)
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                if state.phase != .completed && state.phase != .failed && state.phase != .cancelled {
                    ProgressView(value: state.progress)
                        .tint(LumaColor.accent)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

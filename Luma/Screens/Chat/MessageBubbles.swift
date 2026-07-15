import SwiftUI

/// The Siri reference renders the user's message as a neutral
/// received-gray bubble (dark gray on black, light gray on white) with
/// primary-label text — not an accent-filled "sent" bubble.
struct UserBubble: View {
    var text: String

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(text)
                .font(LumaType.body)
                .foregroundStyle(LumaColor.textPrimary)
                .padding(.horizontal, LumaSpacing.sm)
                .padding(.vertical, LumaSpacing.xs)
                .background(LumaColor.bubble, in: RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
        }
    }
}

struct AssistantBubble: View {
    var text: String
    var isStreaming: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: LumaSpacing.xxs) {
                Text(text)
                    .font(LumaType.body)
                    .foregroundStyle(LumaColor.textPrimary)
                if isStreaming && !text.isEmpty {
                    Rectangle()
                        .fill(LumaColor.accent)
                        .frame(width: 2, height: 14)
                }
            }
            Spacer(minLength: 40)
        }
    }
}

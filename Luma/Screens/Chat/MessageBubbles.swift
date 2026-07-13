import SwiftUI

struct UserBubble: View {
    var text: String

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(text)
                .font(LumaType.body)
                .foregroundStyle(.white)
                .padding(.horizontal, LumaSpacing.sm)
                .padding(.vertical, LumaSpacing.xs)
                .background(LumaColor.accent, in: RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
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

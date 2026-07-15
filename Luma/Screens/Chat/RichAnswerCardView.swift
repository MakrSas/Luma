import SwiftUI

/// Illustrated answer card the agent can attach to a reply — the "widget"
/// concept from the Siri reference screenshots (e.g. the cricket ball detail
/// card, the recipe card). Monochrome to match the rest of the app; the
/// illustration is an SF Symbol on a tinted tile since Stage 1 has no real
/// image pipeline.
struct RichAnswerCardView: View {
    var card: RichAnswerCard

    var body: some View {
        HStack(alignment: .top, spacing: LumaSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: LumaRadius.small, style: .continuous)
                    .fill(LumaColor.textPrimary.opacity(0.06))
                Image(systemName: card.symbolName)
                    .font(.system(size: 26))
                    .foregroundStyle(LumaColor.textPrimary)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(LumaType.subheadline.weight(.semibold))
                    .foregroundStyle(LumaColor.textPrimary)
                    .lineLimit(2)
                Text(card.subtitle)
                    .font(LumaType.footnote)
                    .foregroundStyle(LumaColor.textSecondary)
                    .lineLimit(3)
                Text(card.sourceLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(LumaColor.textTertiary)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(LumaSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumaColor.canvasElevated, in: RoundedRectangle(cornerRadius: LumaRadius.medium, style: .continuous))
    }
}

#Preview {
    RichAnswerCardView(card: RichAnswerCard(
        id: UUID(),
        symbolName: "building.columns.fill",
        title: "Национальный музей антропологии",
        subtitle: "Крупнейший музей Мексики, посвящённый доколумбовым культурам. Открыт ежедневно, кроме понедельника.",
        sourceLabel: "wikipedia.org"
    ))
    .padding()
    .background(LumaColor.canvas)
}

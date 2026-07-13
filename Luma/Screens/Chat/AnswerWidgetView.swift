import SwiftUI

/// Renders a single `AnswerWidget` the way a system widget looks: no card
/// background, no border, no glass — just the ring/icon/text sitting
/// directly on the canvas, per user feedback comparing this to the native
/// Battery widget and a connected-app status row. Per the same feedback,
/// tiles carry no visible caption label (the icon + surrounding reply text
/// carry that meaning) — `caption` still backs VoiceOver.
struct AnswerWidgetView: View {
    var widget: AnswerWidget

    var body: some View {
        switch widget.kind {
        case .compactMetric:
            compactMetric
        case .squareTile:
            squareTile
        case .row:
            row
        }
    }

    private var compactMetric: some View {
        HStack(spacing: LumaSpacing.sm) {
            ring(diameter: 48, lineWidth: 5)
            Text(widget.valueText)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(LumaColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(widget.caption): \(widget.valueText)")
    }

    private var squareTile: some View {
        VStack(spacing: LumaSpacing.xs) {
            ring(diameter: 64, lineWidth: 6)
            Text(widget.valueText)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(LumaColor.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 128)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(widget.caption): \(widget.valueText)")
    }

    private var row: some View {
        HStack(spacing: LumaSpacing.sm) {
            ring(diameter: 44, lineWidth: 4)
            VStack(alignment: .leading, spacing: 1) {
                Text(widget.caption)
                    .font(LumaType.caption)
                    .foregroundStyle(LumaColor.textSecondary)
                HStack(spacing: LumaSpacing.xxs) {
                    Text(widget.valueText)
                        .font(LumaType.subheadline.weight(.semibold))
                        .foregroundStyle(LumaColor.textPrimary)
                    if let detail = widget.detailText {
                        Text("·")
                            .foregroundStyle(LumaColor.textTertiary)
                        Text(detail)
                            .font(LumaType.subheadline)
                            .foregroundStyle(LumaColor.textSecondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func ring(diameter: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(LumaColor.separator, lineWidth: lineWidth)
            if let progress = widget.progress {
                Circle()
                    .trim(from: 0, to: max(0.02, min(1, progress)))
                    .stroke(widget.tint.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Image(systemName: widget.symbolName)
                .font(.system(size: diameter * 0.36, weight: .medium))
                .foregroundStyle(LumaColor.textPrimary)
            if let badge = widget.badgeSymbolName {
                Image(systemName: badge)
                    .font(.system(size: diameter * 0.24, weight: .bold))
                    .foregroundStyle(widget.tint.color)
                    .offset(x: diameter * 0.02, y: -diameter * 0.36)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Composes one or more widgets from an agent turn. `compactMetric`/`row`
/// widgets render at their natural inline size; `squareTile` widgets lay out
/// as an even 2-column grid, mirroring how system widgets stack together.
struct AnswerWidgetGridView: View {
    var widgets: [AnswerWidget]

    private let columns = [GridItem(.flexible(), spacing: LumaSpacing.sm), GridItem(.flexible(), spacing: LumaSpacing.sm)]

    var body: some View {
        if widgets.count == 1 {
            AnswerWidgetView(widget: widgets[0])
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: LumaSpacing.sm) {
                ForEach(widgets) { widget in
                    AnswerWidgetView(widget: widget)
                }
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: LumaSpacing.lg) {
        AnswerWidgetGridView(widgets: [
            AnswerWidget(id: UUID(), kind: .compactMetric, symbolName: "iphone", badgeSymbolName: nil, progress: 0.76, tint: .neutral, valueText: "76 %", detailText: nil, caption: "Аккумулятор")
        ])
        AnswerWidgetGridView(widgets: [
            AnswerWidget(id: UUID(), kind: .squareTile, symbolName: "iphone", badgeSymbolName: nil, progress: 0.76, tint: .neutral, valueText: "76 %", detailText: nil, caption: "Аккумулятор"),
            AnswerWidget(id: UUID(), kind: .squareTile, symbolName: "internaldrive.fill", badgeSymbolName: nil, progress: 0.27, tint: .neutral, valueText: "34 ГБ", detailText: nil, caption: "Свободно")
        ])
        AnswerWidgetView(widget: AnswerWidget(id: UUID(), kind: .row, symbolName: "car.fill", badgeSymbolName: nil, progress: 0.48, tint: .success, valueText: "48%", detailText: "141.8 км", caption: "Ares"))
    }
    .padding()
    .background(LumaColor.canvas)
}

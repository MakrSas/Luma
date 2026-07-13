import SwiftUI

/// Simple two-column masonry layout used for the history grid. Places each
/// subview into whichever column is currently shortest, producing the
/// asymmetric composition (cards of different heights) called for in the
/// history screen design.
struct MasonryLayout: Layout {
    var columns: Int = 2
    var spacing: CGFloat = LumaSpacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.width ?? 0
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var columnHeights = [CGFloat](repeating: 0, count: columns)

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let shortest = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] })!
            columnHeights[shortest] += size.height + spacing
        }

        let height = (columnHeights.max() ?? 0)
        return CGSize(width: width, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let width = bounds.width
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var columnHeights = [CGFloat](repeating: 0, count: columns)

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            let column = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] })!
            let x = bounds.minX + CGFloat(column) * (columnWidth + spacing)
            let y = bounds.minY + columnHeights[column]
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: columnWidth, height: size.height))
            columnHeights[column] += size.height + spacing
        }
    }
}

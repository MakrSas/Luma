import SwiftUI

/// The shape an answer widget renders in. This is the "catalog" the agent
/// picks from when it decides a `get_device_status`-style tool result (or
/// similar structured data) is better shown as a native widget than as
/// prose — mirroring system widgets like Settings' Battery tile or a
/// connected-app status row, per DESIGN.md.
enum AnswerWidgetKind: String, Hashable, CaseIterable {
    /// One value on its own: ring gauge + icon beside a big value, inline.
    /// Used when the agent's whole answer is a single metric.
    case compactMetric
    /// Square tile: ring gauge + icon, big value below. Matches the system
    /// Battery widget. Composable — several lay out together as a grid.
    case squareTile
    /// Single full-width row: small ring + icon, caption, value line.
    /// Matches a connected-app status row (e.g. a car's battery/range).
    case row
}

enum AnswerWidgetTint: Hashable {
    case neutral, success, warning, danger

    var color: Color {
        switch self {
        case .neutral: return LumaColor.textPrimary
        case .success: return LumaColor.success
        case .warning: return LumaColor.warning
        case .danger: return LumaColor.danger
        }
    }
}

struct AnswerWidget: Identifiable, Hashable {
    let id: UUID
    var kind: AnswerWidgetKind
    var symbolName: String
    var badgeSymbolName: String?
    var progress: Double?
    var tint: AnswerWidgetTint
    var valueText: String
    var detailText: String?
    var caption: String
}

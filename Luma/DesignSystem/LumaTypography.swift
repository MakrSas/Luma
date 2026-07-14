import SwiftUI

/// Type scale for Luma. System fonts only (Dynamic Type friendly) — no
/// custom font design (no serif/rounded styling invented for branding).
enum LumaType {
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static let title = Font.system(.title2, design: .default, weight: .semibold)
    static let headline = Font.system(.headline, design: .default, weight: .semibold)
    static let body = Font.system(.body, design: .default)
    static let subheadline = Font.system(.subheadline, design: .default)
    static let footnote = Font.system(.footnote, design: .default)
    static let caption = Font.system(.caption, design: .default)
    static let monospaceCaption = Font.system(.caption, design: .monospaced)
}

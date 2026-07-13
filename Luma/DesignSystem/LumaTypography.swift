import SwiftUI

/// Type scale for Luma. Leans on system fonts (Dynamic Type friendly) with
/// serif display for the largest headlines, echoing the editorial feel of the
/// reference concepts without imitating any specific system UI.
enum LumaType {
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static let title = Font.system(.title2, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .default, weight: .semibold)
    static let body = Font.system(.body, design: .default)
    static let subheadline = Font.system(.subheadline, design: .default)
    static let footnote = Font.system(.footnote, design: .default)
    static let caption = Font.system(.caption, design: .default)
    static let monospaceCaption = Font.system(.caption, design: .monospaced)
}

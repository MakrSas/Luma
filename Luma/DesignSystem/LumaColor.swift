import SwiftUI

/// Luma's visual identity: strictly monochrome (black/white "ink" on a
/// neutral canvas). No brand accent color — interactive/selected elements
/// use the inverted label color instead. Semantic risk colors
/// (success/warning/danger) are the one exception: they carry safety
/// information in confirmations and stay legible functional colors, the
/// same way the Siri reference screenshots keep a green battery ring in an
/// otherwise monochrome UI.
///
/// The grayscale is pure-neutral (r == g == b), matching the iOS 27 Siri
/// app references exactly — the earlier warm-tinted neutrals are gone. In
/// dark mode the canvas is true black, like the Siri conversation screen.
enum LumaColor {
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Ink accent: black in light mode, white in dark mode. Used for
    /// interactive foregrounds, selected states, and filled controls.
    static let accent = dynamic(
        light: UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1),
        dark: UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
    )

    /// Contrasting foreground for content drawn on top of an `accent` fill.
    static let onAccent = dynamic(
        light: UIColor.white,
        dark: UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1)
    )

    /// True black in dark mode (the Siri conversation/history background);
    /// soft neutral gray in light so white cards read against it.
    static let canvas = dynamic(
        light: UIColor(red: 0.949, green: 0.949, blue: 0.945, alpha: 1),
        dark: UIColor.black
    )

    /// Card fill: pure white on the light canvas, #1C1C1E on black —
    /// exactly the history-card pairing in the Siri references.
    static let canvasElevated = dynamic(
        light: UIColor.white,
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
    )

    /// Received-message gray for the user's chat bubble (the reference
    /// renders it as a neutral iMessage-style bubble, not an accent fill).
    static let bubble = dynamic(
        light: UIColor(red: 0.914, green: 0.914, blue: 0.922, alpha: 1),
        dark: UIColor(red: 0.173, green: 0.173, blue: 0.180, alpha: 1)
    )

    static let textPrimary = dynamic(
        light: UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1),
        dark: UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
    )

    static let textSecondary = dynamic(
        light: UIColor(red: 0.42, green: 0.42, blue: 0.42, alpha: 1),
        dark: UIColor(red: 0.64, green: 0.64, blue: 0.64, alpha: 1)
    )

    static let textTertiary = dynamic(
        light: UIColor(red: 0.58, green: 0.58, blue: 0.58, alpha: 1),
        dark: UIColor(red: 0.46, green: 0.46, blue: 0.46, alpha: 1)
    )

    static let separator = dynamic(
        light: UIColor(red: 0.84, green: 0.84, blue: 0.84, alpha: 1),
        dark: UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
    )

    static let success = dynamic(
        light: UIColor(red: 0.20, green: 0.55, blue: 0.32, alpha: 1),
        dark: UIColor(red: 0.42, green: 0.78, blue: 0.53, alpha: 1)
    )

    static let warning = dynamic(
        light: UIColor(red: 0.80, green: 0.55, blue: 0.10, alpha: 1),
        dark: UIColor(red: 0.96, green: 0.74, blue: 0.30, alpha: 1)
    )

    static let danger = dynamic(
        light: UIColor(red: 0.75, green: 0.24, blue: 0.20, alpha: 1),
        dark: UIColor(red: 0.94, green: 0.42, blue: 0.38, alpha: 1)
    )

    /// Risk-level colors for tool confirmation cards.
    static func risk(_ level: RiskLevel) -> Color {
        switch level {
        case .low: return success
        case .medium: return warning
        case .high: return danger
        }
    }
}

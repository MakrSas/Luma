import SwiftUI

/// Luma's visual identity: strictly monochrome (black/white "ink" on a
/// neutral canvas). No brand accent color — interactive/selected elements
/// use the inverted label color instead. Semantic risk colors
/// (success/warning/danger) are the one exception: they carry safety
/// information in confirmations and stay legible functional colors, the
/// same way the Siri reference screenshots keep a green battery ring in an
/// otherwise monochrome UI.
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

    static let canvas = dynamic(
        light: UIColor(red: 0.97, green: 0.965, blue: 0.955, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.06, blue: 0.065, alpha: 1)
    )

    static let canvasElevated = dynamic(
        light: UIColor.white,
        dark: UIColor(red: 0.11, green: 0.11, blue: 0.115, alpha: 1)
    )

    static let textPrimary = dynamic(
        light: UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1),
        dark: UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1)
    )

    static let textSecondary = dynamic(
        light: UIColor(red: 0.42, green: 0.40, blue: 0.37, alpha: 1),
        dark: UIColor(red: 0.68, green: 0.66, blue: 0.63, alpha: 1)
    )

    static let textTertiary = dynamic(
        light: UIColor(red: 0.60, green: 0.58, blue: 0.55, alpha: 1),
        dark: UIColor(red: 0.48, green: 0.47, blue: 0.45, alpha: 1)
    )

    static let separator = dynamic(
        light: UIColor(red: 0.85, green: 0.84, blue: 0.81, alpha: 1),
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

import SwiftUI

/// Central place for Luma's Liquid Glass usage.
///
/// Uses the real `glassEffect` / `GlassEffectContainer` API where available
/// (iOS 26+) and falls back to `.ultraThinMaterial` on earlier systems.
/// Per DESIGN.md, glass is reserved for chrome — input bar, navigation,
/// pickers, floating controls, confirmations — never as a layer over the
/// entire primary content.
enum LumaGlass {
    /// Wraps content that hosts multiple glass elements so they can morph
    /// and merge together (e.g. the input bar + attached pickers).
    @ViewBuilder
    static func container<Content: View>(spacing: CGFloat = LumaSpacing.xs, @ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat = LumaRadius.medium
    var tint: Color? = nil
    var interactive: Bool = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            content.glassEffect(
                tint == nil ? .regular : .regular.tint(tint),
                in: shape
            )
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(LumaColor.separator.opacity(0.5), lineWidth: 0.5)
                )
        }
    }
}

struct GlassPill: ViewModifier {
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content.modifier(GlassSurface(cornerRadius: LumaRadius.pill, tint: tint))
    }
}

extension View {
    /// Standard glass card surface (buttons, panels, confirmation sheets).
    func glassSurface(cornerRadius: CGFloat = LumaRadius.medium, tint: Color? = nil) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius, tint: tint))
    }

    /// Pill-shaped glass (chips, mode switcher segments, floating buttons).
    func glassPill(tint: Color? = nil) -> some View {
        modifier(GlassPill(tint: tint))
    }

    /// Applies a native glass button style where available.
    @ViewBuilder
    func lumaGlassButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }

    /// Real system style (`.glassProminent`/`.borderedProminent`). The
    /// system's own label-contrast computation was previously rendering
    /// white-on-near-white in dark mode, so callers must set an explicit
    /// `.foregroundStyle(LumaColor.onAccent)` on their label content rather
    /// than relying on automatic contrast. Takes the tint directly (rather
    /// than a separate chained `.tint()`) since a `.tint()` applied by the
    /// caller after this modifier would be overridden by one applied inside it.
    @ViewBuilder
    func lumaGlassProminentButtonStyle(tint: Color = LumaColor.accent) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent).tint(tint)
        } else {
            self.buttonStyle(.borderedProminent).tint(tint)
        }
    }
}

import CoreGraphics

enum LumaSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum LumaRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 20
    static let large: CGFloat = 28
    static let pill: CGFloat = 999
}

enum LumaSize {
    /// Every standalone circular icon button (chat "+"/send, history
    /// filter/search/compose) shares this one diameter — previously these
    /// ranged from 44 to 56pt across screens with no consistent rule.
    static let iconButton: CGFloat = 48
}

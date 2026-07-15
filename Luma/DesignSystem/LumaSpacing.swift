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
    /// History-card radius measured against the Siri reference renders
    /// (cards ~170pt wide with a ~24pt continuous corner).
    static let card: CGFloat = 24
    static let large: CGFloat = 28
    static let pill: CGFloat = 999
}

import Foundation

/// Shared between the Luma app and the LumaWidgets Live Activity extension,
/// since `LumaColor.risk(_:)` (used by both targets) needs this type in scope.
enum RiskLevel: String, Hashable, CaseIterable {
    case low, medium, high

    var label: String {
        switch self {
        case .low: return "Низкий риск"
        case .medium: return "Средний риск"
        case .high: return "Высокий риск"
        }
    }
}

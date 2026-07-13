import Foundation

enum Route: Hashable {
    case conversation(UUID)
    case history
    case settingsHub
    case modelCatalog
    case modelDetail(String)
    case modelDownload(String)
    case intelligenceSettings
    case permissionsCenter
    case memory
    case memoryEditor(UUID?)
    case actionLog
    case performanceSettings
    case diagnostics
    case licenses
}

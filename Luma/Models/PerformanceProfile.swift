import Foundation

enum PerformanceProfile: String, CaseIterable, Identifiable, Hashable {
    case batterySaver
    case balanced
    case maxQuality

    var id: String { rawValue }

    var title: String {
        switch self {
        case .batterySaver: return "Экономия батареи"
        case .balanced: return "Сбалансированный"
        case .maxQuality: return "Максимальное качество"
        }
    }

    var detail: String {
        switch self {
        case .batterySaver: return "Меньший контекст, более короткий кэш, приоритет скорости и температуры."
        case .balanced: return "Разумный баланс между качеством ответа и расходом памяти."
        case .maxQuality: return "Больше контекста и повторных проверок. Быстрее расходует батарею."
        }
    }
}

struct DiagnosticsSnapshot {
    var deviceModel: String = "iPhone 15"
    var chip: String = "A16 Bionic"
    var totalRAMGB: Double = 6.0
    var availableRAMGB: Double = 2.1
    var activeModelName: String = "Luma Mini 4B"
    var contextWindowUsed: Int = 1240
    var contextWindowTotal: Int = 4096
    var lastTokenSpeed: Double = 18.4
    var lastTimeToFirstTokenMs: Int = 410
    var thermalState: String = "Норма"
    var storageAvailableGB: Double = 34.2
    var storageTotalGB: Double = 128.0
    var batteryPercent: Int = 76
    var isCharging: Bool = false
}

import UIKit

/// Real device battery/storage readings via `UIDevice`/`FileManager` —
/// replaces the `DiagnosticsSnapshot` mock numbers for anything the agent
/// actually reports back to the user (the `get_device_status` tool
/// concept). `DiagnosticsSnapshot` itself stays mock for now; it only backs
/// the internal Diagnostics settings screen, not user-facing answers.
enum DeviceStatusProvider {
    struct BatteryStatus {
        var percent: Int
        var isCharging: Bool
    }

    static func batteryStatus() -> BatteryStatus {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let percent = level < 0 ? 100 : Int((level * 100).rounded())
        let state = UIDevice.current.batteryState
        let isCharging = state == .charging || state == .full
        return BatteryStatus(percent: percent, isCharging: isCharging)
    }

    /// Free / total capacity of the volume the app lives on, in GB.
    static func storageStatus() -> (freeGB: Double, totalGB: Double) {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return (0, 0)
        }
        let free = Double(values.volumeAvailableCapacityForImportantUsage ?? 0) / 1_000_000_000
        let total = Double(values.volumeTotalCapacity ?? 0) / 1_000_000_000
        return (free, total)
    }

    static var systemVersion: String { UIDevice.current.systemVersion }
    static var deviceModelName: String { UIDevice.current.name }
}

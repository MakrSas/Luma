import Foundation
import LocalLLMClient

/// Argument-less tools all share this empty schema.
private struct NoArguments: Decodable, ToolSchemaGeneratable {
    static var argumentsSchema: LLMToolArgumentsSchema { [:] }
}

/// Real device tools the model can choose to call on its own — this is
/// what replaced the earlier keyword-matching `DeviceIntent` heuristic in
/// `ChatView`. Each tool reads live data via `DeviceStatusProvider`; there
/// is nothing mocked here, only the *decision* to call one is made by the
/// model instead of substring matching.
struct GetBatteryStatusTool: LLMTool {
    static let toolName = "get_battery_status"
    let name = GetBatteryStatusTool.toolName
    let description = "Get the iPhone's current battery level (percent) and whether it is currently charging."
    typealias Arguments = NoArguments

    func call(arguments: NoArguments) async throws -> ToolOutput {
        let status = DeviceStatusProvider.batteryStatus()
        return ToolOutput(data: [
            "batteryPercent": status.percent,
            "isCharging": status.isCharging
        ])
    }
}

struct GetStorageStatusTool: LLMTool {
    static let toolName = "get_storage_status"
    let name = GetStorageStatusTool.toolName
    let description = "Get the iPhone's free and total on-device storage, in gigabytes."
    typealias Arguments = NoArguments

    func call(arguments: NoArguments) async throws -> ToolOutput {
        let status = DeviceStatusProvider.storageStatus()
        return ToolOutput(data: [
            "freeStorageGB": Int(status.freeGB),
            "totalStorageGB": Int(status.totalGB)
        ])
    }
}

struct GetSystemVersionTool: LLMTool {
    static let toolName = "get_system_version"
    let name = GetSystemVersionTool.toolName
    let description = "Get the iOS version currently running on this iPhone."
    typealias Arguments = NoArguments

    func call(arguments: NoArguments) async throws -> ToolOutput {
        ToolOutput(data: ["iosVersion": DeviceStatusProvider.systemVersion])
    }
}

enum DeviceTools {
    /// All device tools available to the model in a chat turn.
    static let all: [any LLMTool] = [
        GetBatteryStatusTool(),
        GetStorageStatusTool(),
        GetSystemVersionTool()
    ]
}

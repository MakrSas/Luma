import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Shared between the Luma app and the LumaWidgets Live Activity extension.
enum AgentRunPhase: String, Codable, Hashable {
    case preparing
    case loadingModel
    case analyzing
    case planning
    case runningTool
    case waitingForConfirmation
    case generating
    case completed
    case failed
    case cancelled
    case paused

    var label: String {
        switch self {
        case .preparing: return "Подготовка"
        case .loadingModel: return "Загрузка модели"
        case .analyzing: return "Анализ запроса"
        case .planning: return "Планирование"
        case .runningTool: return "Выполнение инструмента"
        case .waitingForConfirmation: return "Ожидание подтверждения"
        case .generating: return "Генерация ответа"
        case .completed: return "Готово"
        case .failed: return "Ошибка"
        case .cancelled: return "Отменено"
        case .paused: return "Приостановлено"
        }
    }

    var systemImage: String {
        switch self {
        case .preparing: return "hourglass"
        case .loadingModel: return "square.stack.3d.up.fill"
        case .analyzing: return "text.magnifyingglass"
        case .planning: return "list.bullet.clipboard"
        case .runningTool: return "gearshape.2.fill"
        case .waitingForConfirmation: return "questionmark.circle.fill"
        case .generating: return "sparkles"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
}

#if canImport(ActivityKit)
struct LumaAgentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: AgentRunPhase
        var toolName: String?
        var previewText: String
        var progress: Double
        var conversationID: UUID
    }

    var conversationTitle: String
}
#endif

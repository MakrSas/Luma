import ActivityKit
import WidgetKit
import Foundation

extension LumaAgentActivityAttributes {
    static var preview: LumaAgentActivityAttributes {
        LumaAgentActivityAttributes(conversationTitle: "Отпуск в Мехико")
    }
}

extension LumaAgentActivityAttributes.ContentState {
    static var loadingModel: Self {
        .init(phase: .loadingModel, toolName: nil, previewText: "Загрузка Luma Mini 4B…", progress: 0.2, conversationID: UUID())
    }

    static var runningTool: Self {
        .init(phase: .runningTool, toolName: "create_reminder", previewText: "Создаётся напоминание «Музей антропологии»", progress: 0.6, conversationID: UUID())
    }

    static var waitingForConfirmation: Self {
        .init(phase: .waitingForConfirmation, toolName: "update_calendar_event", previewText: "Подтвердите перенос встречи", progress: 0.7, conversationID: UUID())
    }

    static var generating: Self {
        .init(phase: .generating, toolName: nil, previewText: "Парк разделён на четыре зоны…", progress: 0.85, conversationID: UUID())
    }

    static var completed: Self {
        .init(phase: .completed, toolName: nil, previewText: "Готово", progress: 1.0, conversationID: UUID())
    }
}

#Preview("Lock Screen", as: .content, using: LumaAgentActivityAttributes.preview) {
    LumaAgentLiveActivity()
} contentStates: {
    LumaAgentActivityAttributes.ContentState.loadingModel
    LumaAgentActivityAttributes.ContentState.runningTool
    LumaAgentActivityAttributes.ContentState.waitingForConfirmation
    LumaAgentActivityAttributes.ContentState.generating
    LumaAgentActivityAttributes.ContentState.completed
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: LumaAgentActivityAttributes.preview) {
    LumaAgentLiveActivity()
} contentStates: {
    LumaAgentActivityAttributes.ContentState.runningTool
    LumaAgentActivityAttributes.ContentState.waitingForConfirmation
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: LumaAgentActivityAttributes.preview) {
    LumaAgentLiveActivity()
} contentStates: {
    LumaAgentActivityAttributes.ContentState.generating
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: LumaAgentActivityAttributes.preview) {
    LumaAgentLiveActivity()
} contentStates: {
    LumaAgentActivityAttributes.ContentState.generating
}

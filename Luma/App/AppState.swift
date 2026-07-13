import SwiftUI
import Observation

/// Root observable app state for Stage 1 (mock data only).
@Observable
final class AppState {
    var conversations: [Conversation] = Conversation.mockList
    var activeConversationID: Conversation.ID?

    var availableModels: [LocalModel] = LocalModel.mockCatalog
    var selectedModelID: LocalModel.ID = LocalModel.mockCatalog.first(where: { $0.isRecommended })?.id ?? LocalModel.mockCatalog[0].id

    var intelligenceMode: IntelligenceMode = .auto
    var permissions: [ToolPermission] = ToolPermission.mockList
    var memoryRecords: [MemoryRecord] = MemoryRecord.mockList
    var memoryMode: MemoryMode = .askBeforeSaving
    var actionLog: [ActionLogEntry] = ActionLogEntry.mockList
    var performanceProfile: PerformanceProfile = .balanced

    var isTemporaryChatActive: Bool = false

    var activeConversation: Conversation? {
        get { conversations.first(where: { $0.id == activeConversationID }) }
    }

    func startNewConversation(temporary: Bool = false) {
        let conversation = Conversation.newEmpty(temporary: temporary)
        if !temporary {
            conversations.insert(conversation, at: 0)
        }
        activeConversationID = conversation.id
        isTemporaryChatActive = temporary
    }

    func selectedModel() -> LocalModel {
        availableModels.first(where: { $0.id == selectedModelID }) ?? availableModels[0]
    }
}

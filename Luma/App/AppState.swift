import SwiftUI
import Observation

/// Root observable app state for Stage 1 (mock data only).
@Observable
final class AppState {
    var conversations: [Conversation] = Conversation.mockList
    var activeConversationID: Conversation.ID?
    var temporaryConversation: Conversation?

    var availableModels: [LocalModel] = LocalModel.mockCatalog
    var selectedModelID: LocalModel.ID = LocalModel.mockCatalog.first(where: { $0.isRecommended })?.id ?? LocalModel.mockCatalog[0].id

    var intelligenceMode: IntelligenceMode = .auto
    var permissions: [ToolPermission] = ToolPermission.mockList
    var memoryRecords: [MemoryRecord] = MemoryRecord.mockList
    var memoryMode: MemoryMode = .askBeforeSaving
    var actionLog: [ActionLogEntry] = ActionLogEntry.mockList
    var performanceProfile: PerformanceProfile = .balanced

    func conversation(id: UUID) -> Conversation? {
        conversations.first(where: { $0.id == id }) ?? (temporaryConversation?.id == id ? temporaryConversation : nil)
    }

    @discardableResult
    func startNewConversation(temporary: Bool = false) -> UUID {
        let conversation = Conversation.newEmpty(temporary: temporary)
        if temporary {
            temporaryConversation = conversation
        } else {
            conversations.insert(conversation, at: 0)
        }
        activeConversationID = conversation.id
        return conversation.id
    }

    func selectedModel() -> LocalModel {
        availableModels.first(where: { $0.id == selectedModelID }) ?? availableModels[0]
    }
}

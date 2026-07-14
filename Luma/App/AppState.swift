import SwiftUI
import Observation

/// Root observable app state. Most catalogs here (conversations, memory,
/// permissions, action log) are still Stage 1 mock data — but `availableModels`
/// and `selectedModelID` reflect real files on disk (see `ModelDownloader`)
/// and drive the real `MLXInferenceEngine`.
@Observable
final class AppState {
    var conversations: [Conversation] = Conversation.mockList
    var activeConversationID: Conversation.ID?

    var availableModels: [LocalModel]
    var selectedModelID: LocalModel.ID

    var intelligenceMode: IntelligenceMode = .auto
    var permissions: [ToolPermission] = ToolPermission.mockList
    var memoryRecords: [MemoryRecord] = MemoryRecord.mockList
    var memoryMode: MemoryMode = .askBeforeSaving
    var actionLog: [ActionLogEntry] = ActionLogEntry.mockList
    var performanceProfile: PerformanceProfile = .balanced

    let inferenceEngine: LocalInferenceEngine = MLXInferenceEngine()

    init() {
        let models = LocalModel.mockCatalog.map { model -> LocalModel in
            var model = model
            if ModelDownloader.isDownloaded(model) {
                model.downloadState = .installed
            }
            return model
        }
        availableModels = models
        selectedModelID = models.first(where: { $0.downloadState == .installed })?.id
            ?? models.first(where: { $0.isRecommended })?.id
            ?? models[0].id
    }

    func conversation(id: UUID) -> Conversation? {
        conversations.first(where: { $0.id == id })
    }

    @discardableResult
    func startNewConversation() -> UUID {
        let conversation = Conversation.newEmpty()
        conversations.insert(conversation, at: 0)
        activeConversationID = conversation.id
        return conversation.id
    }

    func selectedModel() -> LocalModel {
        availableModels.first(where: { $0.id == selectedModelID }) ?? availableModels[0]
    }
}

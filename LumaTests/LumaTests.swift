import XCTest
@testable import Luma

final class LumaTests: XCTestCase {
    func testMockConversationsAreNotEmpty() {
        XCTAssertFalse(Conversation.mockList.isEmpty)
    }

    func testMockModelCatalogHasRecommendedModel() {
        XCTAssertTrue(LocalModel.mockCatalog.contains(where: { $0.isRecommended }))
    }

    func testAppStateSelectsRecommendedModelByDefault() {
        let state = AppState()
        XCTAssertEqual(state.selectedModel().id, LocalModel.mockCatalog.first(where: { $0.isRecommended })?.id)
    }

    func testStartNewConversationCreatesActiveConversation() {
        let state = AppState()
        let countBefore = state.conversations.count
        state.startNewConversation(temporary: false)
        XCTAssertEqual(state.conversations.count, countBefore + 1)
        XCTAssertNotNil(state.activeConversationID)
        XCTAssertEqual(state.activeConversationID, state.conversations.first?.id)
    }

    func testTemporaryConversationIsNotStored() {
        let state = AppState()
        let countBefore = state.conversations.count
        let id = state.startNewConversation(temporary: true)
        XCTAssertEqual(state.conversations.count, countBefore)
        XCTAssertEqual(state.temporaryConversation?.id, id)
        XCTAssertEqual(state.conversation(id: id)?.id, id)
    }

    func testIntelligenceModeHasFourCases() {
        XCTAssertEqual(IntelligenceMode.allCases.count, 4)
    }

    func testPermissionStateHasThreeCases() {
        XCTAssertEqual(PermissionState.allCases.count, 3)
    }
}

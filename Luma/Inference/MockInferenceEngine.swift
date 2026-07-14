import Foundation
import LocalLLMClient

/// Used by SwiftUI Previews, tests, and as the explicit "no model
/// downloaded yet" state — never silently substituted for a real answer
/// during normal use (see `ChatView`, which shows a distinct prompt to
/// download a model instead of routing through this).
final class MockInferenceEngine: LocalInferenceEngine {
    private(set) var isReady: Bool = true

    func load(modelFileURL: URL, tools: [any LLMTool]) async throws {}

    func unload() {}

    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<InferenceEvent, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let reply = "Это ответ мокового движка (MockInferenceEngine) — используется в Preview и тестах, не в реальном чате."
                for character in reply {
                    try? await Task.sleep(nanoseconds: 12_000_000)
                    continuation.yield(.token(String(character)))
                }
                continuation.finish()
            }
        }
    }

    func cancelGeneration() {}
}

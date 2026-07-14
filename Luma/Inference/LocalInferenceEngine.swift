import Foundation
import LocalLLMClient

/// A single turn's worth of context: a system prompt (tool/persona
/// instructions) and the conversation so far. Kept intentionally small for
/// this first real-inference slice — the full `ModelContextBuilder` from
/// ARCHITECTURE.md's Stage 3 plan will replace this once the agent
/// framework exists.
struct InferenceRequest {
    var systemPrompt: String
    var messages: [(role: InferenceRole, text: String)]
}

enum InferenceRole {
    case user
    case assistant
}

enum InferenceError: Error {
    case noModelLoaded
    case modelFileMissing
    case cancelled
    case underlying(Error)
}

/// One unit of a generation stream: either a piece of the model's own text,
/// or a signal that it decided (on its own — real function-calling, not a
/// keyword heuristic) to invoke one of the tools passed to `generate`.
/// Callers that want to react to a specific tool (e.g. attaching an
/// `AnswerWidget`) match on `name`.
enum InferenceEvent: Sendable {
    case token(String)
    case toolCall(name: String)
}

/// Abstraction over "something that can turn a prompt into streamed
/// tokens, optionally calling tools along the way." `MockInferenceEngine`
/// backs Previews and the no-model-downloaded state; `MLXInferenceEngine`
/// runs a real downloaded MLX model (through the LocalLLMClient package).
protocol LocalInferenceEngine: AnyObject {
    /// True once a model is loaded and ready to generate.
    var isReady: Bool { get }

    /// Loads (or reloads, if a different model was previously loaded) the
    /// given model directory into memory, with the set of tools the model
    /// may call for the lifetime of this load (the underlying MLX client
    /// fixes its tool schema at construction, not per generation call). Per
    /// DESIGN/ARCHITECTURE constraints, only one model is ever resident at
    /// a time — callers must `unload()` (or simply `load` a different URL,
    /// which unloads the previous one first) rather than holding several
    /// engines alive.
    func load(modelFileURL: URL, tools: [any LLMTool]) async throws

    /// Releases the loaded model's memory.
    func unload()

    /// Streams generation events for the given request. Throws
    /// `InferenceError.noModelLoaded` if `load` hasn't succeeded yet.
    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<InferenceEvent, Error>

    /// Cancels any in-flight `generate` call.
    func cancelGeneration()
}

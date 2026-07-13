import Foundation

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

/// Abstraction over "something that can turn a prompt into streamed text
/// tokens." `MockInferenceEngine` backs Previews and the no-model-downloaded
/// state; `LlamaInferenceEngine` runs a real downloaded GGUF model via
/// llama.cpp (through the LocalLLMClient package).
protocol LocalInferenceEngine: AnyObject {
    /// True once a model is loaded and ready to generate.
    var isReady: Bool { get }

    /// Loads (or reloads, if a different model was previously loaded) the
    /// given GGUF file into memory. Per DESIGN/ARCHITECTURE constraints,
    /// only one model is ever resident at a time — callers must `unload()`
    /// (or simply `load` a different URL, which unloads the previous one
    /// first) rather than holding several engines alive.
    func load(modelFileURL: URL) async throws

    /// Releases the loaded model's memory.
    func unload()

    /// Streams generated text for the given request. Throws
    /// `InferenceError.noModelLoaded` if `load` hasn't succeeded yet.
    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<String, Error>

    /// Cancels any in-flight `generate` call.
    func cancelGeneration()
}

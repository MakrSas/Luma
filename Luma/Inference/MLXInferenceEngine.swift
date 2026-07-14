import Foundation
import LocalLLMClient
import LocalLLMClientMLX

/// Real local inference over a downloaded MLX model directory, via Apple's
/// MLX framework (through the LocalLLMClient package's MLX backend).
///
/// This is MLX, not llama.cpp/GGUF as ARCHITECTURE.md originally sketched:
/// LocalLLMClient's llama.cpp backend (`LocalLLMClientLlama`) has a
/// confirmed, still-open upstream packaging bug (dangling symlinks into a
/// git submodule that Swift Package Manager never fetches — see
/// github.com/tattn/LocalLLMClient/issues/94), so any SPM consumer's build
/// fails, not just Luma's. MLX is pure Swift/Metal with no such issue and
/// runs natively on iPhone's Apple Silicon, so it's the real, working path
/// for Stage 5 rather than a placeholder. `LocalModel` catalog entries now
/// point at `mlx-community` model directories instead of single GGUF files.
///
/// Only ever holds one loaded model at a time — `load(modelFileURL:tools:)`
/// unloads whatever was previously resident first, per the "don't keep
/// several large models in memory" constraint from ARCHITECTURE.md.
///
/// Real function-calling, not a keyword heuristic: `MLXClient.responseStream`
/// only *detects* a tool call and stops — it doesn't execute it or continue
/// generation on its own (verified against the library's source; there's no
/// hidden auto-loop). `generate` below is a small manual agent loop: collect
/// any tool calls the model makes, run them via `AnyLLMTool.call`, and
/// `resumeStream` with the results so the model can produce its final
/// answer grounded in the real tool output.
final class MLXInferenceEngine: LocalInferenceEngine {
    private var client: MLXClient?
    private var loadedURL: URL?
    private var loadedTools: [AnyLLMTool] = []
    private var generationTask: Task<Void, Never>?

    var isReady: Bool { client != nil }

    /// `modelFileURL` here is a *directory* (MLX models ship as a folder of
    /// weights + tokenizer files, not one file) containing a downloaded
    /// `mlx-community` model snapshot.
    func load(modelFileURL: URL, tools: [any LLMTool]) async throws {
        if loadedURL == modelFileURL, client != nil { return }
        unload()
        guard FileManager.default.fileExists(atPath: modelFileURL.path) else {
            throw InferenceError.modelFileMissing
        }
        do {
            client = try await MLXClient(
                url: modelFileURL,
                parameter: .init(maxTokens: 512, temperature: 0.6, topP: 0.9),
                tools: tools
            )
            loadedURL = modelFileURL
            loadedTools = tools.map { AnyLLMTool($0) }
        } catch {
            throw InferenceError.underlying(error)
        }
    }

    func unload() {
        cancelGeneration()
        client = nil
        loadedURL = nil
        loadedTools = []
    }

    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<InferenceEvent, Error> {
        AsyncThrowingStream { continuation in
            guard let client else {
                continuation.finish(throwing: InferenceError.noModelLoaded)
                return
            }

            var messages: [LLMInput.Message] = [.system(request.systemPrompt)]
            messages += request.messages.map { turn in
                switch turn.role {
                case .user: return LLMInput.Message.user(turn.text)
                case .assistant: return LLMInput.Message.assistant(turn.text)
                }
            }
            let input = LLMInput.chat(messages)
            let tools = loadedTools

            generationTask = Task {
                do {
                    let initialStream = try await client.responseStream(from: input)
                    let toolCalls = try await Self.streamChunks(
                        from: initialStream,
                        continuation: continuation
                    )
                    guard !toolCalls.isEmpty else {
                        continuation.finish()
                        return
                    }

                    var outputs: [(String, String)] = []
                    for call in toolCalls {
                        try Task.checkCancellation()
                        continuation.yield(.toolCall(name: call.name))
                        guard let tool = tools.first(where: { $0.name == call.name }) else { continue }
                        let output = try await tool.call(argumentsJSON: call.arguments)
                        outputs.append((call.id, Self.jsonString(from: output)))
                    }

                    let resumed = try await client.resumeStream(
                        withToolCalls: toolCalls,
                        toolOutputs: outputs,
                        originalInput: input
                    )
                    _ = try await Self.streamChunks(from: resumed, continuation: continuation)
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: InferenceError.cancelled)
                } catch {
                    continuation.finish(throwing: InferenceError.underlying(error))
                }
            }
        }
    }

    /// Drains a `StreamingChunk` stream, forwarding text as `.token` events
    /// and collecting (but not forwarding — the caller reports those after
    /// deciding execution order) any tool calls the model made.
    private static func streamChunks(
        from stream: AsyncThrowingStream<StreamingChunk, Error>,
        continuation: AsyncThrowingStream<InferenceEvent, Error>.Continuation
    ) async throws -> [LLMToolCall] {
        var toolCalls: [LLMToolCall] = []
        for try await chunk in stream {
            try Task.checkCancellation()
            switch chunk {
            case .text(let text):
                continuation.yield(.token(text))
            case .toolCall(let call):
                toolCalls.append(call)
            }
        }
        return toolCalls
    }

    private static func jsonString(from output: ToolOutput) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: output.data, options: [.sortedKeys]) {
            return String(decoding: data, as: UTF8.self)
        }
        return output.data.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
    }
}

import Foundation
import LocalLLMClient
import LocalLLMClientLlama

/// Real local inference over a downloaded GGUF model, via llama.cpp through
/// the LocalLLMClient package. Only ever holds one loaded model at a time —
/// `load(modelFileURL:)` unloads whatever was previously resident first,
/// per the "don't keep several large models in memory" constraint from
/// ARCHITECTURE.md.
final class LlamaInferenceEngine: LocalInferenceEngine {
    private var client: LlamaClient?
    private var loadedURL: URL?
    private var generationTask: Task<Void, Never>?

    var isReady: Bool { client != nil }

    func load(modelFileURL: URL) async throws {
        if loadedURL == modelFileURL, client != nil { return }
        unload()
        guard FileManager.default.fileExists(atPath: modelFileURL.path) else {
            throw InferenceError.modelFileMissing
        }
        do {
            client = try await LocalLLMClient.llama(
                url: modelFileURL,
                parameter: .init(temperature: 0.7, topP: 0.9)
            )
            loadedURL = modelFileURL
        } catch {
            throw InferenceError.underlying(error)
        }
    }

    func unload() {
        cancelGeneration()
        client = nil
        loadedURL = nil
    }

    func generate(_ request: InferenceRequest) -> AsyncThrowingStream<String, Error> {
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

            generationTask = Task {
                do {
                    for try await text in try await client.textStream(from: input) {
                        if Task.isCancelled {
                            continuation.finish(throwing: InferenceError.cancelled)
                            return
                        }
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: InferenceError.underlying(error))
                }
            }
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
    }
}

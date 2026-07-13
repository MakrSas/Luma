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
/// Only ever holds one loaded model at a time — `load(modelFileURL:)`
/// unloads whatever was previously resident first, per the "don't keep
/// several large models in memory" constraint from ARCHITECTURE.md.
final class MLXInferenceEngine: LocalInferenceEngine {
    private var client: MLXClient?
    private var loadedURL: URL?
    private var generationTask: Task<Void, Never>?

    var isReady: Bool { client != nil }

    /// `modelFileURL` here is a *directory* (MLX models ship as a folder of
    /// weights + tokenizer files, not one file) containing a downloaded
    /// `mlx-community` model snapshot.
    func load(modelFileURL: URL) async throws {
        if loadedURL == modelFileURL, client != nil { return }
        unload()
        guard FileManager.default.fileExists(atPath: modelFileURL.path) else {
            throw InferenceError.modelFileMissing
        }
        do {
            client = try await MLXClient(
                url: modelFileURL,
                parameter: .init(maxTokens: 512, temperature: 0.6, topP: 0.9)
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
                    let stream = try await client.textStream(from: input)
                    for await text in stream {
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

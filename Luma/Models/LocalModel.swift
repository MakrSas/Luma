import Foundation

/// A single file that must be present in a model's local directory before
/// it can be loaded. Mirrors the real file listing HuggingFace reports for
/// each `mlx-community` repo (`huggingFaceRepoID`) — not invented.
struct ModelFile: Hashable {
    var filename: String
    var sizeBytes: Int64
    /// SHA-256 of the file's contents, when known (HuggingFace's git-lfs
    /// `oid` for the large weights file). Verified after download; nil for
    /// small config/tokenizer files where a mismatch would just fail to
    /// parse anyway.
    var sha256: String?
}

struct LocalModel: Identifiable, Hashable {
    enum DownloadState: Hashable {
        case notDownloaded
        case downloading(progress: Double)
        case verifying
        case installed
        case failed(reason: String)
    }

    /// Also the HuggingFace repo id, e.g. "mlx-community/Qwen2.5-1.5B-Instruct-4bit".
    var id: String
    var huggingFaceRepoID: String { id }
    var name: String
    var developer: String
    var family: String
    var parameterCount: String
    var quantization: String
    var requiredFiles: [ModelFile]
    var estimatedRAMUsageGB: Double
    var russianQuality: Int
    var codeQuality: Int
    var toolCallingQuality: Int
    var reasoningQuality: Int
    var speed: Int
    var overallScore: Int
    var license: String
    var isCompatibleWithDevice: Bool
    var isRecommended: Bool
    var downloadState: DownloadState
    var summary: String

    var downloadSizeGB: Double {
        Double(requiredFiles.reduce(Int64(0)) { $0 + $1.sizeBytes }) / 1_000_000_000
    }
}

extension LocalModel {
    /// Real, verified `mlx-community` MLX model repos on HuggingFace — file
    /// names, sizes and the weights file's SHA-256 come straight from the
    /// HuggingFace API, not invented. Quality ratings (1–5) are qualitative,
    /// informed by Qwen2.5's published capabilities, not benchmarked
    /// on-device — Luma doesn't run its own evals yet.
    static let mockCatalog: [LocalModel] = [
        LocalModel(
            id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit",
            name: "Qwen2.5 1.5B Instruct (4-bit)",
            developer: "Alibaba Cloud (Qwen team) · mlx-community",
            family: "Qwen2.5 Instruct",
            parameterCount: "1.5B",
            quantization: "MLX 4-bit",
            requiredFiles: [
                ModelFile(filename: "config.json", sizeBytes: 784),
                ModelFile(filename: "tokenizer_config.json", sizeBytes: 7_308),
                ModelFile(filename: "special_tokens_map.json", sizeBytes: 613),
                ModelFile(filename: "added_tokens.json", sizeBytes: 605),
                ModelFile(filename: "vocab.json", sizeBytes: 2_776_833),
                ModelFile(filename: "merges.txt", sizeBytes: 1_671_853),
                ModelFile(filename: "tokenizer.json", sizeBytes: 7_031_673),
                ModelFile(filename: "model.safetensors.index.json", sizeBytes: 51_569),
                ModelFile(
                    filename: "model.safetensors",
                    sizeBytes: 868_628_559,
                    sha256: "0979f33d1bc58afcf696d13f57977644e7b11a6f0eec3e631d8e9463d18c0717"
                )
            ],
            estimatedRAMUsageGB: 1.4,
            russianQuality: 3,
            codeQuality: 3,
            toolCallingQuality: 3,
            reasoningQuality: 2,
            speed: 5,
            overallScore: 3,
            license: "Apache 2.0",
            isCompatibleWithDevice: true,
            isRecommended: true,
            downloadState: .notDownloaded,
            summary: "Компактная модель по умолчанию для iPhone с 6 ГБ памяти. Быстрая, но по сложным рассуждениям и русскому языку заметно слабее крупных моделей — честно, это 1.5B."
        ),
        LocalModel(
            id: "mlx-community/Qwen2.5-0.5B-Instruct-4bit",
            name: "Qwen2.5 0.5B Instruct (4-bit)",
            developer: "Alibaba Cloud (Qwen team) · mlx-community",
            family: "Qwen2.5 Instruct",
            parameterCount: "0.5B",
            quantization: "MLX 4-bit",
            requiredFiles: [
                ModelFile(filename: "config.json", sizeBytes: 783),
                ModelFile(filename: "tokenizer_config.json", sizeBytes: 7_308),
                ModelFile(filename: "special_tokens_map.json", sizeBytes: 613),
                ModelFile(filename: "added_tokens.json", sizeBytes: 605),
                ModelFile(filename: "vocab.json", sizeBytes: 2_776_833),
                ModelFile(filename: "merges.txt", sizeBytes: 1_671_853),
                ModelFile(filename: "tokenizer.json", sizeBytes: 7_031_673),
                ModelFile(filename: "model.safetensors.index.json", sizeBytes: 44_209),
                ModelFile(
                    filename: "model.safetensors",
                    sizeBytes: 278_064_920,
                    sha256: "ddffab9cbc7bf6dde941c6724841eeca8981fcfa81ca20ff8efff1396326d153"
                )
            ],
            estimatedRAMUsageGB: 0.6,
            russianQuality: 2,
            codeQuality: 2,
            toolCallingQuality: 2,
            reasoningQuality: 1,
            speed: 5,
            overallScore: 2,
            license: "Apache 2.0",
            isCompatibleWithDevice: true,
            isRecommended: false,
            downloadState: .notDownloaded,
            summary: "Самая маленькая и быстрая модель каталога. Годится для короткой демонстрации инструментов, но рассуждает заметно слабее — на неё не стоит полагаться в сложных вопросах."
        ),
        LocalModel(
            id: "mlx-community/Qwen3-4B-4bit",
            name: "Qwen3 4B (4-bit)",
            developer: "Alibaba Cloud (Qwen team) · mlx-community",
            family: "Qwen3",
            parameterCount: "4B",
            quantization: "MLX 4-bit",
            requiredFiles: [
                ModelFile(filename: "config.json", sizeBytes: 937),
                ModelFile(filename: "tokenizer_config.json", sizeBytes: 9_706),
                ModelFile(filename: "special_tokens_map.json", sizeBytes: 613),
                ModelFile(filename: "added_tokens.json", sizeBytes: 707),
                ModelFile(filename: "vocab.json", sizeBytes: 2_776_833),
                ModelFile(filename: "merges.txt", sizeBytes: 1_671_853),
                ModelFile(filename: "tokenizer.json", sizeBytes: 11_422_654, sha256: "aeb13307a71acd8fe81861d94ad54ab689df773318809eed3cbe794b4492dae4"),
                ModelFile(filename: "model.safetensors.index.json", sizeBytes: 63_924),
                ModelFile(
                    filename: "model.safetensors",
                    sizeBytes: 2_263_022_529,
                    sha256: "e240c0bdc0ebb0681bf0da0f98d9719fd6ebe269a3633f81542c13e81345651d"
                )
            ],
            estimatedRAMUsageGB: 3.6,
            russianQuality: 4,
            codeQuality: 4,
            toolCallingQuality: 4,
            reasoningQuality: 4,
            speed: 2,
            overallScore: 4,
            license: "Apache 2.0",
            isCompatibleWithDevice: true,
            isRecommended: false,
            downloadState: .notDownloaded,
            summary: "Заметно умнее модели по умолчанию — лучше рассуждает и точнее следует инструкциям, но весит почти 2.3 ГБ и генерирует медленнее. На iPhone 15 (6 ГБ ОЗУ) занимает существенную часть памяти; лучше не держать параллельно тяжёлые приложения."
        )
    ]
}

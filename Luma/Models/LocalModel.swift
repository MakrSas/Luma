import Foundation

struct LocalModel: Identifiable, Hashable {
    enum DownloadState: Hashable {
        case notDownloaded
        case downloading(progress: Double)
        case paused(progress: Double)
        case verifying
        case installed
        case failed(reason: String)
    }

    let id: String
    var name: String
    var developer: String
    var family: String
    var parameterCount: String
    var quantization: String
    var downloadSizeGB: Double
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
}

extension LocalModel {
    static let mockCatalog: [LocalModel] = [
        LocalModel(
            id: "luma-mini-4b-q4",
            name: "Luma Mini 4B",
            developer: "Сообщество открытых моделей",
            family: "Compact Instruct",
            parameterCount: "4B",
            quantization: "Q4_K_M",
            downloadSizeGB: 2.4,
            estimatedRAMUsageGB: 2.9,
            russianQuality: 4,
            codeQuality: 3,
            toolCallingQuality: 4,
            reasoningQuality: 3,
            speed: 5,
            overallScore: 4,
            license: "Apache 2.0",
            isCompatibleWithDevice: true,
            isRecommended: true,
            downloadState: .installed,
            summary: "Быстрая модель по умолчанию для iPhone с 6 ГБ памяти. Хорошо справляется с инструментами и короткими ответами."
        ),
        LocalModel(
            id: "open-instruct-7b-q4",
            name: "Open Instruct 7B",
            developer: "Открытое сообщество",
            family: "Instruct",
            parameterCount: "7B",
            quantization: "Q4_0",
            downloadSizeGB: 4.1,
            estimatedRAMUsageGB: 4.8,
            russianQuality: 4,
            codeQuality: 4,
            toolCallingQuality: 3,
            reasoningQuality: 4,
            speed: 3,
            overallScore: 4,
            license: "Apache 2.0",
            isCompatibleWithDevice: true,
            isRecommended: false,
            downloadState: .notDownloaded,
            summary: "Более крупная модель для сложных рассуждений. Работает медленнее, требует больше памяти."
        ),
        LocalModel(
            id: "code-focus-3b-q4",
            name: "Code Focus 3B",
            developer: "Сообщество открытых моделей",
            family: "Code",
            parameterCount: "3B",
            quantization: "Q4_K_M",
            downloadSizeGB: 1.9,
            estimatedRAMUsageGB: 2.3,
            russianQuality: 2,
            codeQuality: 5,
            toolCallingQuality: 3,
            reasoningQuality: 3,
            speed: 5,
            overallScore: 3,
            license: "MIT",
            isCompatibleWithDevice: true,
            isRecommended: false,
            downloadState: .downloading(progress: 0.42),
            summary: "Специализация на коде и рефакторинге. Слабее в диалоге на русском языке."
        ),
        LocalModel(
            id: "reasoning-plus-13b-q4",
            name: "Reasoning Plus 13B",
            developer: "Открытая лаборатория",
            family: "Reasoning",
            parameterCount: "13B",
            quantization: "Q4_K_M",
            downloadSizeGB: 7.6,
            estimatedRAMUsageGB: 8.2,
            russianQuality: 5,
            codeQuality: 4,
            toolCallingQuality: 4,
            reasoningQuality: 5,
            speed: 1,
            overallScore: 4,
            license: "Llama 3 Community License",
            isCompatibleWithDevice: false,
            isRecommended: false,
            downloadState: .notDownloaded,
            summary: "Требует больше памяти, чем доступно на iPhone 15. Показан для будущих устройств."
        )
    ]
}

import Foundation
import CryptoKit

/// Real (not simulated) model download: fetches every required file for a
/// `LocalModel` from HuggingFace into local storage, verifies the large
/// weights file's SHA-256 against the manifest, and exposes combined
/// byte-weighted progress across all files. Per DESIGN/ARCHITECTURE, models
/// never ship in the app bundle — this is the only way one becomes usable.
enum ModelDownloader {
    enum DownloadError: LocalizedError {
        case badResponse(Int)
        case hashMismatch(expected: String, actual: String)

        var errorDescription: String? {
            switch self {
            case .badResponse(let code):
                return "Сервер вернул код \(code)"
            case .hashMismatch:
                return "Проверка SHA-256 не прошла — файл повреждён или подменён"
            }
        }
    }

    static var modelsDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func localDirectory(for model: LocalModel) -> URL {
        modelsDirectory.appendingPathComponent(
            model.id.replacingOccurrences(of: "/", with: "_"), isDirectory: true
        )
    }

    /// True only when every required file already exists locally.
    static func isDownloaded(_ model: LocalModel) -> Bool {
        let dir = localDirectory(for: model)
        return model.requiredFiles.allSatisfy {
            FileManager.default.fileExists(atPath: dir.appendingPathComponent($0.filename).path)
        }
    }

    static func delete(_ model: LocalModel) {
        try? FileManager.default.removeItem(at: localDirectory(for: model))
    }

    /// Downloads every missing file (files already present from a prior,
    /// interrupted attempt are skipped — the closest thing to "resumable"
    /// without per-byte resume data, see KNOWN_ISSUES.md), then verifies
    /// the weights file's hash. Reports fraction-complete across the whole
    /// multi-file download, weighted by each file's byte size.
    static func download(_ model: LocalModel, onProgress: @escaping @Sendable (Double) -> Void) async throws {
        let dir = localDirectory(for: model)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let totalBytes = model.requiredFiles.reduce(Int64(0)) { $0 + $1.sizeBytes }
        var completedBytes: Int64 = model.requiredFiles.reduce(Int64(0)) { partial, file in
            let path = dir.appendingPathComponent(file.filename).path
            return FileManager.default.fileExists(atPath: path) ? partial + file.sizeBytes : partial
        }
        onProgress(totalBytes > 0 ? Double(completedBytes) / Double(totalBytes) : 0)

        for file in model.requiredFiles {
            try Task.checkCancellation()
            let destination = dir.appendingPathComponent(file.filename)
            guard !FileManager.default.fileExists(atPath: destination.path) else { continue }

            guard let remoteURL = URL(
                string: "https://huggingface.co/\(model.huggingFaceRepoID)/resolve/main/\(file.filename)"
            ) else { continue }

            let alreadyCompleted = completedBytes
            let tempURL = try await SingleFileDownloader.download(from: remoteURL) { bytesWritten in
                onProgress(Double(alreadyCompleted + bytesWritten) / Double(max(totalBytes, 1)))
            }

            if let expectedHash = file.sha256 {
                let actualHash = try sha256Hex(of: tempURL)
                guard actualHash.lowercased() == expectedHash.lowercased() else {
                    try? FileManager.default.removeItem(at: tempURL)
                    throw DownloadError.hashMismatch(expected: expectedHash, actual: actualHash)
                }
            }

            try FileManager.default.moveItem(at: tempURL, to: destination)
            completedBytes += file.sizeBytes
            onProgress(Double(completedBytes) / Double(max(totalBytes, 1)))
        }
    }

    private static func sha256Hex(of fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: 4 * 1024 * 1024) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

/// Thin `URLSessionDownloadDelegate` bridge: the async `download(from:)`
/// convenience on `URLSession` only reports completion, not incremental
/// progress, which we need for a multi-hundred-megabyte weights file.
private final class SingleFileDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<URL, Error>?
    private var onProgress: (@Sendable (Int64) -> Void)?
    private var session: URLSession!
    private var task: URLSessionDownloadTask?

    static func download(from url: URL, onProgress: @escaping @Sendable (Int64) -> Void) async throws -> URL {
        let downloader = SingleFileDownloader()
        return try await downloader.run(url: url, onProgress: onProgress)
    }

    private func run(url: URL, onProgress: @escaping @Sendable (Int64) -> Void) async throws -> URL {
        self.onProgress = onProgress
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                let task = session.downloadTask(with: url)
                self.task = task
                task.resume()
            }
        } onCancel: { [weak self] in
            self?.task?.cancel()
        }
    }

    func urlSession(
        _ session: URLSession, downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
    ) {
        onProgress?(totalBytesWritten)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempCopy = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.moveItem(at: location, to: tempCopy)
            continuation?.resume(returning: tempCopy)
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            continuation?.resume(throwing: error)
            continuation = nil
        }
        if let response = task.response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
            continuation?.resume(throwing: ModelDownloader.DownloadError.badResponse(response.statusCode))
            continuation = nil
        }
    }
}

import CryptoKit
import Foundation

/// Downloads result videos once and reuses the local file for playback, saving and sharing.
actor VideoFileCache {
    private let directory: URL
    private let session: URLSession
    private var inFlight: [URL: Task<URL, Error>] = [:]

    init(directory: URL = StorageLocation.videoCache, session: URLSession = .shared) {
        self.directory = directory
        self.session = session
    }

    func localFile(for remoteURL: URL) async throws -> URL {
        let destination = directory.appendingPathComponent(Self.fileName(for: remoteURL))
        if FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }
        if let task = inFlight[remoteURL] {
            return try await task.value
        }
        let task = Task { [session, directory] in
            let (temporaryURL, response) = try await session.download(from: remoteURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw APIError.invalidResponse
            }
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            return destination
        }
        inFlight[remoteURL] = task
        defer { inFlight[remoteURL] = nil }
        return try await task.value
    }

    func clear() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    func sizeInBytes() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    private static func fileName(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let pathExtension = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
        return "\(digest).\(pathExtension)"
    }
}

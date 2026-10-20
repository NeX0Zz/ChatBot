import Foundation
import OSLog

/// Serializes a Codable value as JSON in Application Support. Access is isolated by the actor.
actor FileStore<Value: Codable & Sendable> {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let logger = Logger(subsystem: "com.labs.fviu", category: "persistence")

    init(fileName: String, directory: URL = StorageLocation.root) {
        fileURL = directory.appendingPathComponent(fileName)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    /// Returns `nil` when nothing is stored. An unreadable file is moved aside as `*.corrupt`
    /// so the next save can't silently overwrite the user's history with an empty list.
    func load() throws -> Value? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            logger.error("Decoding \(self.fileURL.lastPathComponent) failed: \(error.localizedDescription)")
            try moveAside()
            return nil
        }
    }

    func save(_ value: Value) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(value)
        // Jobs finish while the phone may be locked, so writes must work after the first unlock.
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private func moveAside() throws {
        let backupURL = fileURL.appendingPathExtension("corrupt")
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        try FileManager.default.moveItem(at: fileURL, to: backupURL)
    }
}

import Foundation

/// Runs `body` with a unique empty directory and removes it afterwards.
func withTemporaryDirectory(_ body: (URL) async throws -> Void) async throws {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ChatBotTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: url) }
    try await body(url)
}

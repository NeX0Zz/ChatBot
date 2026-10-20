import Foundation

/// Local list of generations plus the prepared source frames used for retries.
protocol VideoHistoryRepository: Sendable {
    func loadGenerations() async throws -> [VideoGeneration]
    func saveGenerations(_ generations: [VideoGeneration]) async throws
    func storeSourceImage(_ data: Data) async throws -> String
    func sourceImage(named fileName: String) async throws -> Data
    func removeSourceImage(named fileName: String) async
}

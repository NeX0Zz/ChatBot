import Foundation

protocol VideoGenerationRepository: Sendable {
    /// Starts a template generation and returns the backend job id.
    func startGeneration(templateId: Int, imageData: Data, quality: VideoQuality) async throws -> String
    func status(ofJob jobId: String) async throws -> RemoteGenerationStatus
}

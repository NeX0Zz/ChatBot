import Foundation

final class RemoteVideoGenerationRepository: VideoGenerationRepository {
    private let client: APIClient
    private let baseURL: URL

    init(client: APIClient, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }

    func startGeneration(templateId: Int, imageData: Data, quality: VideoQuality) async throws -> String {
        let endpoint = VideoEndpoints.templateToVideo(
            templateId: templateId,
            imageData: imageData,
            quality: quality,
            baseURL: baseURL
        )
        return try await client.send(endpoint, as: CreateVideoResponseDTO.self).videoId
    }

    func status(ofJob jobId: String) async throws -> RemoteGenerationStatus {
        let endpoint = VideoEndpoints.status(jobId: jobId, baseURL: baseURL)
        let response = try await client.send(endpoint, as: GenerationStatusDTO.self)
        return GenerationStatusMapper.map(response)
    }
}

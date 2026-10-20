import Foundation

final class RemoteVideoTemplatesRepository: VideoTemplatesRepository {
    private let client: APIClient
    private let baseURL: URL
    private let applicationId: String

    init(client: APIClient, baseURL: URL, applicationId: String) {
        self.client = client
        self.baseURL = baseURL
        self.applicationId = applicationId
    }

    func fetchTemplates() async throws -> [VideoTemplate] {
        let endpoint = VideoEndpoints.templates(applicationId: applicationId, baseURL: baseURL)
        let response = try await client.send(endpoint, as: TemplatesResponseDTO.self)
        return response.templates
            .filter { $0.isActive ?? true }
            .map(VideoTemplateMapper.map)
    }
}

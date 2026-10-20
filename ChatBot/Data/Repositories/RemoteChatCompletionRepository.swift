import Foundation

final class RemoteChatCompletionRepository: ChatCompletionRepository {
    private let client: APIClient
    private let baseURL: URL

    init(client: APIClient, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }

    func reply(to message: String, chatId: String) async throws -> String {
        let endpoint = try ChatEndpoints.sendMessage(message, chatId: chatId, baseURL: baseURL)
        let response = try await client.send(endpoint, as: SendMessageResponseDTO.self)
        return response.assistantMessage
    }
}

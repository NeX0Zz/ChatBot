import Foundation

enum ChatEndpoints {
    static func sendMessage(_ message: String, chatId: String, baseURL: URL) throws -> Endpoint {
        Endpoint(
            baseURL: baseURL,
            path: "dola/chats/\(chatId)/messages",
            method: .post,
            body: try .json(SendMessageRequestDTO(message: message))
        )
    }
}

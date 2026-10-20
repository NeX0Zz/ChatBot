import Foundation

/// Produces assistant replies. The backend keeps conversation context per `chatId`.
protocol ChatCompletionRepository: Sendable {
    func reply(to message: String, chatId: String) async throws -> String
}

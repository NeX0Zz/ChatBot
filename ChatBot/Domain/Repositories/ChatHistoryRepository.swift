import Foundation

/// Local chat history: the source of truth for the chat list, pin state and titles.
protocol ChatHistoryRepository: Sendable {
    func loadChats() async throws -> [Chat]
    func saveChats(_ chats: [Chat]) async throws
}

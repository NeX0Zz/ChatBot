import Foundation

struct StoredChat: Codable, Sendable {
    struct Message: Codable, Sendable {
        let id: UUID
        let role: String
        let text: String
        let createdAt: Date
    }

    let id: UUID
    let title: String
    let isPinned: Bool
    let createdAt: Date
    let updatedAt: Date
    let messages: [Message]
}

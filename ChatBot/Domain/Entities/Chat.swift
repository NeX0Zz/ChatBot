import Foundation

struct Chat: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var isPinned: Bool
    let createdAt: Date
    var updatedAt: Date
    var messages: [ChatMessage]

    init(
        id: UUID = UUID(),
        title: String,
        isPinned: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
    }

    /// Server-side chat identifier. The Dola API scopes chats by user and app, so the local id is reused.
    var remoteId: String { id.uuidString.lowercased() }

    var lastMessagePreview: String {
        messages.last?.text ?? ""
    }
}

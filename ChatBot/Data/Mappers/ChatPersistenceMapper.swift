import Foundation

enum ChatPersistenceMapper {
    static func toStored(_ chat: Chat) -> StoredChat {
        StoredChat(
            id: chat.id,
            title: chat.title,
            isPinned: chat.isPinned,
            createdAt: chat.createdAt,
            updatedAt: chat.updatedAt,
            messages: chat.messages.map {
                StoredChat.Message(id: $0.id, role: $0.role.rawValue, text: $0.text, createdAt: $0.createdAt)
            }
        )
    }

    static func toDomain(_ stored: StoredChat) -> Chat {
        Chat(
            id: stored.id,
            title: stored.title,
            isPinned: stored.isPinned,
            createdAt: stored.createdAt,
            updatedAt: stored.updatedAt,
            messages: stored.messages.compactMap { message in
                guard let role = ChatMessage.Role(rawValue: message.role) else { return nil }
                return ChatMessage(id: message.id, role: role, text: message.text, createdAt: message.createdAt)
            }
        )
    }
}

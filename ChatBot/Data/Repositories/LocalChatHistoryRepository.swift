import Foundation

final class LocalChatHistoryRepository: ChatHistoryRepository {
    private let store: FileStore<PersistenceEnvelope<StoredChat>>

    init(store: FileStore<PersistenceEnvelope<StoredChat>> = FileStore(fileName: "chats.json")) {
        self.store = store
    }

    func loadChats() async throws -> [Chat] {
        let envelope = try await store.load()
        return (envelope?.items ?? []).map(ChatPersistenceMapper.toDomain)
    }

    func saveChats(_ chats: [Chat]) async throws {
        try await store.save(PersistenceEnvelope(items: chats.map(ChatPersistenceMapper.toStored)))
    }
}

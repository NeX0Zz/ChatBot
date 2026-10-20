import Foundation
import Testing
@testable import ChatBot

@Suite("LocalChatHistoryRepository")
struct LocalChatHistoryRepositoryTests {
    private typealias Store = FileStore<PersistenceEnvelope<StoredChat>>

    @Test("Loads an empty list when nothing is stored")
    func emptyByDefault() async throws {
        try await withTemporaryDirectory { directory in
            let repository = LocalChatHistoryRepository(store: Store(fileName: "chats.json", directory: directory))

            let result1 = try await repository.loadChats()
            #expect(result1.isEmpty)
        }
    }

    @Test("Saved chats come back identical and in order")
    func roundTrip() async throws {
        try await withTemporaryDirectory { directory in
            let repository = LocalChatHistoryRepository(store: Store(fileName: "chats.json", directory: directory))
            let chats = [
                Fixtures.chat(title: "First", isPinned: true, messages: [Fixtures.message(role: .user, text: "a"), Fixtures.message(role: .assistant, text: "b")]),
                Fixtures.chat(title: "Second")
            ]

            try await repository.saveChats(chats)

            let result2 = try await repository.loadChats()
            #expect(result2 == chats)
        }
    }

    @Test("Saving an empty list clears the history")
    func saveEmpty() async throws {
        try await withTemporaryDirectory { directory in
            let repository = LocalChatHistoryRepository(store: Store(fileName: "chats.json", directory: directory))
            try await repository.saveChats([Fixtures.chat()])

            try await repository.saveChats([])

            let result3 = try await repository.loadChats()
            #expect(result3.isEmpty)
        }
    }

    @Test("Writes the current schema version")
    func schemaVersion() async throws {
        try await withTemporaryDirectory { directory in
            let store = Store(fileName: "chats.json", directory: directory)
            try await LocalChatHistoryRepository(store: store).saveChats([Fixtures.chat()])

            let envelope = try #require(try await store.load())

            #expect(envelope.schemaVersion == PersistenceEnvelope<StoredChat>.currentVersion)
            #expect(envelope.items.count == 1)
        }
    }

    @Test("Messages with an unknown role are skipped on load")
    func skipsUnknownRoles() async throws {
        try await withTemporaryDirectory { directory in
            let store = Store(fileName: "chats.json", directory: directory)
            let stored = StoredChat(
                id: UUID(), title: "T", isPinned: false, createdAt: Fixtures.referenceDate, updatedAt: Fixtures.referenceDate,
                messages: [
                    StoredChat.Message(id: UUID(), role: "tool", text: "x", createdAt: Fixtures.referenceDate),
                    StoredChat.Message(id: UUID(), role: "user", text: "y", createdAt: Fixtures.referenceDate)
                ]
            )
            try await store.save(PersistenceEnvelope(items: [stored]))

            let chats = try await LocalChatHistoryRepository(store: store).loadChats()

            #expect(chats.first?.messages.map(\.text) == ["y"])
        }
    }

    @Test("A corrupted file loads as an empty history and is kept aside")
    func corruptedFile() async throws {
        try await withTemporaryDirectory { directory in
            try Data("{".utf8).write(to: directory.appendingPathComponent("chats.json"))
            let repository = LocalChatHistoryRepository(store: Store(fileName: "chats.json", directory: directory))

            let chats = try await repository.loadChats()

            #expect(chats.isEmpty)
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("chats.json.corrupt").path))
        }
    }
}

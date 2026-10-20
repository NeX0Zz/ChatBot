import Foundation
import Testing
@testable import ChatBot

@Suite("ChatPersistenceMapper")
struct ChatPersistenceMapperTests {
    @Test("Domain to stored and back preserves the chat")
    func roundTrip() {
        let chat = Fixtures.chat(
            title: "Trip plans",
            isPinned: true,
            messages: [
                Fixtures.message(role: .user, text: "Where to go?"),
                Fixtures.message(role: .assistant, text: "Lisbon.")
            ],
            updatedAt: Fixtures.referenceDate.addingTimeInterval(60)
        )

        let restored = ChatPersistenceMapper.toDomain(ChatPersistenceMapper.toStored(chat))

        #expect(restored == chat)
    }

    @Test("Stored form uses raw role strings")
    func storedRoles() {
        let chat = Fixtures.chat(messages: [Fixtures.message(role: .user), Fixtures.message(role: .assistant)])

        let stored = ChatPersistenceMapper.toStored(chat)

        #expect(stored.messages.map(\.role) == ["user", "assistant"])
    }

    @Test("Messages with an unknown role are dropped, the rest survive")
    func dropsUnknownRole() {
        let good = Fixtures.message(text: "keep")
        let stored = StoredChat(
            id: UUID(),
            title: "T",
            isPinned: false,
            createdAt: Fixtures.referenceDate,
            updatedAt: Fixtures.referenceDate,
            messages: [
                StoredChat.Message(id: UUID(), role: "system", text: "drop", createdAt: Fixtures.referenceDate),
                StoredChat.Message(id: good.id, role: "user", text: "keep", createdAt: good.createdAt)
            ]
        )

        let chat = ChatPersistenceMapper.toDomain(stored)

        #expect(chat.messages == [good])
    }

    @Test("Chat without messages round-trips to an empty list")
    func emptyMessages() {
        let chat = Fixtures.chat(messages: [])

        #expect(ChatPersistenceMapper.toDomain(ChatPersistenceMapper.toStored(chat)).messages.isEmpty)
    }
}

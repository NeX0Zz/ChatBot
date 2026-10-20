import Foundation
import Testing
@testable import ChatBot

@MainActor
@Suite("ChatStore")
struct ChatStoreTests {
    private func makeStore(
        chats: [Chat] = [],
        loadError: Error? = nil
    ) -> (ChatStore, FakeChatHistoryRepository) {
        let repository = FakeChatHistoryRepository(chats: chats, loadError: loadError)
        return (ChatStore(repository: repository), repository)
    }

    // MARK: - Load

    @Test("Starts empty and not loaded")
    func initialState() {
        let (store, _) = makeStore(chats: [Fixtures.chat()])

        #expect(store.chats.isEmpty)
        #expect(store.isLoaded == false)
    }

    @Test("Load publishes stored chats and flips isLoaded")
    func load() async {
        let chats = [Fixtures.chat(title: "A"), Fixtures.chat(title: "B")]
        let (store, _) = makeStore(chats: chats)

        await store.load()

        #expect(store.chats == chats)
        #expect(store.isLoaded)
    }

    @Test("Load failure leaves the list empty but marks the store loaded")
    func loadFailure() async {
        let (store, _) = makeStore(loadError: StubError())

        await store.load()

        #expect(store.chats.isEmpty)
        #expect(store.isLoaded)
    }

    @Test("After a failed load edits stay in memory but are never written over the unreadable history")
    func persistenceBlockedAfterLoadFailure() async {
        let (store, repository) = makeStore(loadError: StubError())
        await store.load()
        let chat = Fixtures.chat()

        store.upsert(chat)
        store.rename(id: chat.id, to: "Renamed")
        await store.flush()

        #expect(store.chat(id: chat.id)?.title == "Renamed")
        #expect(repository.saves.isEmpty)
    }

    @Test("A successful load keeps persistence enabled")
    func persistenceEnabledAfterLoad() async {
        let (store, repository) = makeStore(chats: [Fixtures.chat(title: "Old")])
        await store.load()

        store.upsert(Fixtures.chat(title: "New"))
        await store.flush()

        #expect(repository.saves.count == 1)
        #expect(repository.saves.last?.count == 2)
    }

    // MARK: - Flush

    @Test("flush writes the pending snapshot immediately")
    func flushWritesPending() async {
        let (store, repository) = makeStore()
        let chat = Fixtures.chat()
        store.upsert(chat)

        await store.flush()

        #expect(repository.saves == [[chat]])
    }

    @Test("flush without pending changes writes nothing")
    func flushWithoutChanges() async {
        let (store, repository) = makeStore()

        await store.flush()

        #expect(repository.saves.isEmpty)
    }

    @Test("flush cancels the debounce so the data is written once")
    func flushReplacesDebounce() async {
        let (store, repository) = makeStore()
        store.upsert(Fixtures.chat())

        await store.flush()
        await store.flush()

        #expect(repository.saves.count == 1)
    }

    @Test("flush saves the latest state after several edits")
    func flushLatestState() async {
        let (store, repository) = makeStore()
        let chat = Fixtures.chat(title: "Draft")
        store.upsert(chat)
        store.rename(id: chat.id, to: "Final")
        store.setPinned(true, id: chat.id)

        await store.flush()

        #expect(repository.saves.count == 1)
        #expect(repository.saves.last?.first?.title == "Final")
        #expect(repository.saves.last?.first?.isPinned == true)
    }

    @Test("Load reads the repository only once")
    func loadIsIdempotent() async {
        let (store, repository) = makeStore(chats: [Fixtures.chat()])

        await store.load()
        await store.load()

        #expect(repository.loadCount == 1)
    }

    // MARK: - Upsert

    @Test("Upsert ignores chats without messages")
    func upsertIgnoresEmpty() {
        let (store, _) = makeStore()

        store.upsert(Fixtures.chat(messages: []))

        #expect(store.chats.isEmpty)
    }

    @Test("Upsert inserts new chats at the top")
    func upsertInsertsAtTop() {
        let (store, _) = makeStore()
        let first = Fixtures.chat(title: "First")
        let second = Fixtures.chat(title: "Second")

        store.upsert(first)
        store.upsert(second)

        #expect(store.chats.map(\.title) == ["Second", "First"])
    }

    @Test("Upsert replaces an existing chat in place")
    func upsertReplaces() {
        let (store, _) = makeStore()
        let first = Fixtures.chat(title: "First")
        let second = Fixtures.chat(title: "Second")
        store.upsert(first)
        store.upsert(second)
        var updated = first
        updated.messages.append(Fixtures.message(role: .assistant, text: "More"))

        store.upsert(updated)

        #expect(store.chats.count == 2)
        #expect(store.chats.map(\.id) == [second.id, first.id])
        #expect(store.chat(id: first.id)?.messages.count == 2)
    }

    @Test("Upserting a chat that became empty keeps the stored version")
    func upsertEmptyKeepsExisting() {
        let (store, _) = makeStore()
        let chat = Fixtures.chat()
        store.upsert(chat)
        var emptied = chat
        emptied.messages = []

        store.upsert(emptied)

        #expect(store.chat(id: chat.id)?.messages.count == 1)
    }

    @Test("chat(id:) finds chats and returns nil for unknown ids")
    func lookup() {
        let (store, _) = makeStore()
        let chat = Fixtures.chat()
        store.upsert(chat)

        #expect(store.chat(id: chat.id) == chat)
        #expect(store.chat(id: UUID()) == nil)
    }

    // MARK: - Rename

    @Test("Rename trims whitespace")
    func renameTrims() {
        let (store, _) = makeStore()
        let chat = Fixtures.chat(title: "Old")
        store.upsert(chat)

        store.rename(id: chat.id, to: "  New title \n")

        #expect(store.chat(id: chat.id)?.title == "New title")
    }

    @Test("Rename rejects empty and whitespace-only titles", arguments: ["", "   ", "\n\t "])
    func renameRejectsEmpty(title: String) {
        let (store, _) = makeStore()
        let chat = Fixtures.chat(title: "Keep")
        store.upsert(chat)

        store.rename(id: chat.id, to: title)

        #expect(store.chat(id: chat.id)?.title == "Keep")
    }

    @Test("Rename ignores unknown ids")
    func renameUnknown() {
        let (store, _) = makeStore()
        let chat = Fixtures.chat(title: "Keep")
        store.upsert(chat)

        store.rename(id: UUID(), to: "Other")

        #expect(store.chats == [chat])
    }

    // MARK: - Pin, delete

    @Test("setPinned toggles the flag")
    func setPinned() {
        let (store, _) = makeStore()
        let chat = Fixtures.chat()
        store.upsert(chat)

        store.setPinned(true, id: chat.id)
        #expect(store.chat(id: chat.id)?.isPinned == true)

        store.setPinned(false, id: chat.id)
        #expect(store.chat(id: chat.id)?.isPinned == false)
    }

    @Test("setPinned ignores unknown ids")
    func setPinnedUnknown() {
        let (store, _) = makeStore()
        let chat = Fixtures.chat()
        store.upsert(chat)

        store.setPinned(true, id: UUID())

        #expect(store.chats == [chat])
    }

    @Test("Delete removes only the given chat")
    func delete() {
        let (store, _) = makeStore()
        let keep = Fixtures.chat(title: "Keep")
        let drop = Fixtures.chat(title: "Drop")
        store.upsert(keep)
        store.upsert(drop)

        store.delete(id: drop.id)

        #expect(store.chats == [keep])
    }

    @Test("Delete of an unknown id changes nothing")
    func deleteUnknown() {
        let (store, _) = makeStore()
        let chat = Fixtures.chat()
        store.upsert(chat)

        store.delete(id: UUID())

        #expect(store.chats == [chat])
    }

    // MARK: - Persistence

    @Test("Nothing is written synchronously: saves are debounced")
    func saveIsDebounced() {
        let (store, repository) = makeStore()

        store.upsert(Fixtures.chat())

        #expect(repository.saves.isEmpty)
    }

    @Test("Debounce eventually saves the current chats")
    func debounceSaves() async {
        let (store, repository) = makeStore()
        let chat = Fixtures.chat()

        store.upsert(chat)
        await waitUntil { !repository.saves.isEmpty }

        #expect(repository.saves.last == [chat])
    }

    @Test("Rapid edits are coalesced into one save with the final state")
    func coalescesSaves() async {
        let (store, repository) = makeStore()
        let chat = Fixtures.chat(title: "Draft")

        store.upsert(chat)
        store.rename(id: chat.id, to: "Renamed")
        store.setPinned(true, id: chat.id)
        await waitUntil { !repository.saves.isEmpty }

        #expect(repository.saves.count == 1)
        #expect(repository.saves.last?.first?.title == "Renamed")
        #expect(repository.saves.last?.first?.isPinned == true)
    }

    @Test("Ignored mutations do not schedule a save of the rejected data")
    func rejectedMutationsAreNotPersisted() async {
        let (store, repository) = makeStore()
        let chat = Fixtures.chat(title: "Keep")

        store.upsert(Fixtures.chat(messages: []))
        store.upsert(chat)
        store.rename(id: chat.id, to: "   ")
        await waitUntil { !repository.saves.isEmpty }

        #expect(repository.saves.count == 1)
        #expect(repository.saves.last == [chat])
    }

    @Test("Delete is persisted")
    func deletePersisted() async {
        let (store, repository) = makeStore()
        let chat = Fixtures.chat()
        store.upsert(chat)
        store.delete(id: chat.id)

        await waitUntil { !repository.saves.isEmpty }

        #expect(repository.saves.last?.isEmpty == true)
    }

    @Test("A failing save does not break later saves")
    func saveFailureIsSurvivable() async {
        let (store, repository) = makeStore()
        repository.setSaveError(StubError())
        store.upsert(Fixtures.chat(title: "One"))
        await waitUntil { repository.saves.count == 1 }

        repository.setSaveError(nil)
        store.upsert(Fixtures.chat(title: "Two"))
        await waitUntil { repository.saves.count == 2 }

        #expect(store.chats.count == 2)
        #expect(repository.saves.last?.count == 2)
    }
}

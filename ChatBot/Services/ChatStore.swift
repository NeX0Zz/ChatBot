import Combine
import Foundation
import OSLog

/// Single in-memory source of chats shared by the chat screen and History.
/// Every mutation is persisted through `ChatHistoryRepository`.
@MainActor
final class ChatStore: ObservableObject {
    @Published private(set) var chats: [Chat] = []
    @Published private(set) var isLoaded = false

    private let repository: ChatHistoryRepository
    private let logger = Logger(subsystem: "com.labs.fviu", category: "chats")
    private var saveTask: Task<Void, Never>?
    /// Set when the history file could not be read: saving now would replace it with a partial list.
    private var isPersistenceBlocked = false

    init(repository: ChatHistoryRepository) {
        self.repository = repository
    }

    func load() async {
        guard !isLoaded else { return }
        do {
            chats = try await repository.loadChats()
        } catch {
            isPersistenceBlocked = true
            logger.error("Loading chats failed: \(error.localizedDescription)")
        }
        isLoaded = true
    }

    func chat(id: Chat.ID) -> Chat? {
        chats.first { $0.id == id }
    }

    /// Inserts or replaces the chat. Empty chats are never stored.
    func upsert(_ chat: Chat) {
        guard !chat.messages.isEmpty else { return }
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
        } else {
            chats.insert(chat, at: 0)
        }
        persist()
    }

    func rename(id: Chat.ID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[index].title = trimmed
        persist()
    }

    func setPinned(_ isPinned: Bool, id: Chat.ID) {
        guard let index = chats.firstIndex(where: { $0.id == id }) else { return }
        chats[index].isPinned = isPinned
        persist()
    }

    func delete(id: Chat.ID) {
        chats.removeAll { $0.id == id }
        persist()
    }

    /// Writes the pending snapshot right away, e.g. when the app moves to the background.
    func flush() async {
        guard let saveTask else { return }
        saveTask.cancel()
        self.saveTask = nil
        await save(chats)
    }

    /// Saves are coalesced: a send followed by the reply, or a pin right after it, produce one write.
    private func persist() {
        guard !isPersistenceBlocked else { return }
        saveTask?.cancel()
        let snapshot = chats
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await self?.save(snapshot)
            // A newer edit cancels this task and owns `saveTask`; only the latest write clears it.
            if !Task.isCancelled { self?.saveTask = nil }
        }
    }

    private func save(_ snapshot: [Chat]) async {
        do {
            try await repository.saveChats(snapshot)
        } catch {
            logger.error("Saving chats failed: \(error.localizedDescription)")
        }
    }
}

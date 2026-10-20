import Foundation
@testable import ChatBot

final class FakeChatHistoryRepository: ChatHistoryRepository, @unchecked Sendable {
    private struct State {
        var chats: [Chat] = []
        var loadError: Error?
        var saveError: Error?
        var loadCount = 0
        var saves: [[Chat]] = []
    }

    private let state = Locked(State())

    init(chats: [Chat] = [], loadError: Error? = nil, saveError: Error? = nil) {
        state.withLock {
            $0.chats = chats
            $0.loadError = loadError
            $0.saveError = saveError
        }
    }

    var saves: [[Chat]] { state.current.saves }
    var loadCount: Int { state.current.loadCount }

    func setSaveError(_ error: Error?) {
        state.withLock { $0.saveError = error }
    }

    func loadChats() async throws -> [Chat] {
        let (chats, error) = state.withLock { state -> ([Chat], Error?) in
            state.loadCount += 1
            return (state.chats, state.loadError)
        }
        if let error { throw error }
        return chats
    }

    func saveChats(_ chats: [Chat]) async throws {
        let error = state.withLock { state -> Error? in
            state.saves.append(chats)
            return state.saveError
        }
        if let error { throw error }
    }
}

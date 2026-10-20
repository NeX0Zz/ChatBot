import Combine
import Foundation

@MainActor
final class ChatHistoryViewModel: ObservableObject {
    @Published private(set) var sections: [ChatHistorySection] = []
    @Published private(set) var isLoaded = false
    @Published var openRowId: Chat.ID?
    @Published var isRenamePresented = false
    @Published var isDeletePresented = false
    @Published var renameText = ""

    private var targetId: Chat.ID?
    private var cancellables = Set<AnyCancellable>()
    private let store: ChatStore
    private let router: AppRouter

    init(store: ChatStore, router: AppRouter) {
        self.store = store
        self.router = router
        store.$chats
            .removeDuplicates()
            .sink { [weak self] chats in self?.sections = ChatHistorySection.make(from: chats) }
            .store(in: &cancellables)
        store.$isLoaded
            .sink { [weak self] isLoaded in self?.isLoaded = isLoaded }
            .store(in: &cancellables)
    }

    convenience init(container: AppContainer) {
        self.init(store: container.chatStore, router: container.router)
    }

    var isRenameConfirmEnabled: Bool {
        !renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func open(_ chat: Chat) {
        router.push(.chat(id: chat.id))
    }

    func requestRename(_ chat: Chat) {
        openRowId = nil
        targetId = chat.id
        renameText = chat.title
        isRenamePresented = true
    }

    func confirmRename() {
        isRenamePresented = false
        guard let targetId, isRenameConfirmEnabled else { return }
        store.rename(id: targetId, to: renameText)
    }

    func requestDelete(_ chat: Chat) {
        openRowId = nil
        targetId = chat.id
        isDeletePresented = true
    }

    func confirmDelete() {
        isDeletePresented = false
        guard let targetId else { return }
        store.delete(id: targetId)
    }
}

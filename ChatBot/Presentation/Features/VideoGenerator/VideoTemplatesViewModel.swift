import Combine
import Foundation

@MainActor
final class VideoTemplatesViewModel: ObservableObject {
    @Published private(set) var state: Loadable<[VideoTemplate]> = .idle
    @Published private(set) var categories = [VideoTemplatesStore.popularCategory]
    @Published private(set) var visibleTemplates: [VideoTemplate] = []
    @Published private(set) var selectedCategory = VideoTemplatesStore.popularCategory

    private let store: VideoTemplatesStore
    private var cancellable: AnyCancellable?

    init(store: VideoTemplatesStore) {
        self.store = store
        cancellable = store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
        refresh()
    }

    func load() async {
        await store.loadIfNeeded()
    }

    func reload() async {
        await store.reload()
    }

    func select(_ category: String) {
        guard category != selectedCategory else { return }
        selectedCategory = category
        visibleTemplates = store.templates(in: category)
    }

    private func refresh() {
        state = store.state
        categories = store.categories
        if !categories.contains(selectedCategory) {
            selectedCategory = VideoTemplatesStore.popularCategory
        }
        visibleTemplates = store.templates(in: selectedCategory)
    }
}

import Foundation
import Testing
@testable import ChatBot

@MainActor
@Suite("VideoTemplatesStore")
struct VideoTemplatesStoreTests {
    private func templates(_ categories: [String]) -> [VideoTemplate] {
        categories.enumerated().map { Fixtures.template(id: $0.offset + 1, name: "T\($0.offset + 1)", category: $0.element) }
    }

    private func loadedStore(_ categories: [String]) async -> VideoTemplatesStore {
        let store = VideoTemplatesStore(repository: FakeVideoTemplatesRepository(result: .success(templates(categories))))
        await store.reload()
        return store
    }

    // MARK: - Categories

    @Test("Categories start with Popular, then by size descending")
    func categoriesOrdering() async {
        let store = await loadedStore(["A", "B", "B", "C", "C", "C"])

        #expect(store.categories == ["Popular", "C", "B", "A"])
    }

    @Test("Equal sizes are ordered alphabetically")
    func categoriesTieBreak() async {
        let store = await loadedStore(["Zebra", "Apple", "Mango"])

        #expect(store.categories == ["Popular", "Apple", "Mango", "Zebra"])
    }

    @Test("Test category is hidden")
    func hidesTestCategory() async {
        let store = await loadedStore(["Test", "Test", "Test", "Fun"])

        #expect(store.categories == ["Popular", "Fun"])
    }

    @Test("Before loading only Popular is offered")
    func categoriesBeforeLoad() {
        let store = VideoTemplatesStore(repository: FakeVideoTemplatesRepository())

        #expect(store.categories == ["Popular"])
        #expect(store.templates.isEmpty)
    }

    // MARK: - Templates

    @Test("Popular shows every visible template")
    func popularShowsAll() async {
        let store = await loadedStore(["A", "Test", "B"])

        #expect(store.templates(in: "Popular").map(\.id) == [1, 3])
    }

    @Test("A category shows only its templates in catalog order")
    func filtersByCategory() async {
        let store = await loadedStore(["A", "B", "A", "C"])

        #expect(store.templates(in: "A").map(\.id) == [1, 3])
        #expect(store.templates(in: "B").map(\.id) == [2])
    }

    @Test("Unknown and hidden categories are empty")
    func unknownCategory() async {
        let store = await loadedStore(["A", "Test"])

        #expect(store.templates(in: "Missing").isEmpty)
        #expect(store.templates(in: "Test").isEmpty)
    }

    @Test("template(id:) finds templates, including hidden ones, and nil for unknown ids")
    func lookup() async {
        let store = await loadedStore(["A", "Test"])

        #expect(store.template(id: 1)?.category == "A")
        #expect(store.template(id: 2)?.category == "Test")
        #expect(store.template(id: 99) == nil)
    }

    // MARK: - Loading states

    @Test("Initial state is idle")
    func initialState() {
        let store = VideoTemplatesStore(repository: FakeVideoTemplatesRepository())

        #expect(store.state.isIdle)
    }

    @Test("Successful load goes idle, loading, loaded")
    func loadSuccess() async {
        let gate = AsyncGate()
        let repository = FakeVideoTemplatesRepository(result: .success(templates(["A"])), gate: gate)
        let store = VideoTemplatesStore(repository: repository)

        let task = Task { await store.reload() }
        await waitUntil { store.state.isLoading }
        gate.open()
        await task.value

        #expect(store.state.value?.count == 1)
        #expect(store.state.isLoading == false)
    }

    @Test("Failed load exposes the error message")
    func loadFailure() async {
        let store = VideoTemplatesStore(repository: FakeVideoTemplatesRepository(result: .failure(StubError("No catalog"))))

        await store.reload()

        #expect(store.state.errorMessage == "No catalog")
        #expect(store.templates.isEmpty)
    }

    @Test("API errors surface their human-readable text")
    func apiErrorMessage() async {
        let store = VideoTemplatesStore(repository: FakeVideoTemplatesRepository(result: .failure(APIError.offline)))

        await store.reload()

        #expect(store.state.errorMessage == APIError.offline.errorDescription)
    }

    @Test("Cancellation returns the store to idle instead of failed")
    func cancellationIsIdle() async {
        let store = VideoTemplatesStore(repository: FakeVideoTemplatesRepository(result: .failure(CancellationError())))

        await store.reload()

        #expect(store.state.isIdle)
    }

    @Test("loadIfNeeded loads only once after success")
    func loadIfNeededOnce() async {
        let repository = FakeVideoTemplatesRepository(result: .success(templates(["A"])))
        let store = VideoTemplatesStore(repository: repository)

        await store.loadIfNeeded()
        await store.loadIfNeeded()

        #expect(repository.fetchCount == 1)
    }

    @Test("loadIfNeeded does not start a second request while loading")
    func loadIfNeededWhileLoading() async {
        let gate = AsyncGate()
        let repository = FakeVideoTemplatesRepository(result: .success(templates(["A"])), gate: gate)
        let store = VideoTemplatesStore(repository: repository)

        let first = Task { await store.loadIfNeeded() }
        await waitUntil { store.state.isLoading }
        await store.loadIfNeeded()
        gate.open()
        await first.value

        #expect(repository.fetchCount == 1)
        #expect(store.state.value != nil)
    }

    @Test("loadIfNeeded retries after a failure")
    func loadIfNeededRetries() async {
        let repository = FakeVideoTemplatesRepository(result: .failure(StubError()))
        let store = VideoTemplatesStore(repository: repository)
        await store.loadIfNeeded()
        repository.setResult(.success(templates(["A", "B"])))

        await store.loadIfNeeded()

        #expect(repository.fetchCount == 2)
        #expect(store.state.value?.count == 2)
    }

    @Test("reload always refetches")
    func reloadRefetches() async {
        let repository = FakeVideoTemplatesRepository(result: .success(templates(["A"])))
        let store = VideoTemplatesStore(repository: repository)
        await store.reload()
        repository.setResult(.success(templates(["A", "B", "C"])))

        await store.reload()

        #expect(repository.fetchCount == 2)
        #expect(store.templates.count == 3)
    }
}

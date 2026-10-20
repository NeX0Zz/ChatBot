import Foundation
import Testing
@testable import ChatBot

@MainActor
@Suite("SubscriptionManager")
struct SubscriptionManagerTests {
    private func makeSUT(isPremium: Bool = false) -> (SubscriptionManager, FakeSubscriptionRepository) {
        let repository = FakeSubscriptionRepository(hasPremiumAccess: isPremium)
        return (SubscriptionManager(repository: repository), repository)
    }

    private func isNothingToRestore(_ error: Error) -> Bool {
        if case .nothingToRestore = error as? SubscriptionError { return true }
        return false
    }

    // MARK: - Premium state

    @Test("Initial premium state comes from the repository", arguments: [true, false])
    func initialPremium(isPremium: Bool) {
        let (manager, _) = makeSUT(isPremium: isPremium)

        #expect(manager.isPremium == isPremium)
    }

    @Test("Exposes the repository user id")
    func userId() {
        let (manager, repository) = makeSUT()
        repository.userId = "abc"

        #expect(manager.userId == "abc")
    }

    @Test("Repository callbacks update isPremium both ways")
    func premiumCallback() {
        let (manager, repository) = makeSUT()

        repository.onPremiumAccessChange?(true)
        #expect(manager.isPremium)

        repository.onPremiumAccessChange?(false)
        #expect(manager.isPremium == false)
    }

    @Test("start starts the repository and refreshes premium")
    func start() {
        let (manager, repository) = makeSUT()
        repository.hasPremiumAccess = true

        manager.start()

        #expect(repository.startCount == 1)
        #expect(manager.isPremium)
    }

    @Test("Paywall analytics events are forwarded to the repository")
    func paywallAnalytics() {
        let (manager, repository) = makeSUT()

        manager.paywallShown()
        manager.paywallShown()
        manager.paywallClosed()

        #expect(repository.paywallShownCount == 2)
        #expect(repository.paywallClosedCount == 1)
    }

    // MARK: - Purchase

    @Test("Successful purchase unlocks premium right away")
    func purchaseSuccess() async throws {
        let (manager, repository) = makeSUT()
        let product = SubscriptionProduct.fixture(id: "yearly", period: .year, price: 39.99)

        let result = try await manager.purchase(product)

        #expect(result)
        #expect(manager.isPremium)
        #expect(manager.isPurchasing == false)
        #expect(repository.purchasedProducts == [product])
    }

    @Test("Cancelled purchase does not unlock premium")
    func purchaseCancelled() async throws {
        let (manager, repository) = makeSUT()
        repository.purchaseResult = .success(.cancelled)

        let result = try await manager.purchase(.fixture())

        #expect(result == false)
        #expect(manager.isPremium == false)
        #expect(manager.isPurchasing == false)
    }

    @Test("Purchase without entitlement afterwards reports false")
    func purchaseWithoutEntitlement() async throws {
        let (manager, repository) = makeSUT()
        repository.premiumAfterPurchase = false

        let result = try await manager.purchase(.fixture())

        #expect(result == false)
        #expect(manager.isPremium == false)
    }

    @Test("Failed purchase rethrows and re-enables purchasing")
    func purchaseFailure() async {
        let (manager, repository) = makeSUT()
        repository.purchaseResult = .failure(SubscriptionError.purchaseFailed)

        await #expect(throws: SubscriptionError.self) {
            _ = try await manager.purchase(.fixture())
        }

        #expect(manager.isPurchasing == false)
        #expect(manager.isPremium == false)
    }

    @Test("A second purchase while one is running is ignored")
    func doublePurchaseGuard() async throws {
        let (manager, repository) = makeSUT()
        let gate = AsyncGate()
        repository.purchaseGate = gate

        let first = Task { try await manager.purchase(.fixture(id: "a")) }
        await waitUntil { manager.isPurchasing && gate.waiterCount == 1 }
        let second = try await manager.purchase(.fixture(id: "b"))
        gate.open()
        let firstResult = try await first.value

        #expect(second == false)
        #expect(firstResult)
        #expect(repository.purchasedProducts.map(\.id) == ["a"])
        #expect(manager.isPurchasing == false)
    }

    @Test("isPurchasing is true only while the purchase is in flight")
    func isPurchasingFlag() async throws {
        let (manager, repository) = makeSUT()
        let gate = AsyncGate()
        repository.purchaseGate = gate
        #expect(manager.isPurchasing == false)

        let task = Task { try await manager.purchase(.fixture()) }
        await waitUntil { manager.isPurchasing }
        gate.open()
        _ = try await task.value

        #expect(manager.isPurchasing == false)
    }

    // MARK: - Restore

    @Test("Restore with an active subscription succeeds and unlocks premium")
    func restoreSuccess() async throws {
        let (manager, repository) = makeSUT()

        let restored = try await manager.restore()

        #expect(restored)
        #expect(manager.isPremium)
        #expect(repository.restoreCount == 1)
        #expect(manager.isPurchasing == false)
    }

    @Test("Restore with nothing to restore throws nothingToRestore")
    func restoreNothing() async {
        let (manager, repository) = makeSUT()
        repository.restoreResult = .success(false)
        repository.premiumAfterRestore = false

        await #expect {
            _ = try await manager.restore()
        } throws: { error in
            isNothingToRestore(error)
        }

        #expect(manager.isPremium == false)
        #expect(manager.isPurchasing == false)
    }

    @Test("Restore failure is rethrown and re-enables purchasing")
    func restoreFailure() async {
        let (manager, repository) = makeSUT()
        repository.restoreResult = .failure(SubscriptionError.restoreFailed)

        await #expect(throws: SubscriptionError.self) {
            _ = try await manager.restore()
        }

        #expect(manager.isPurchasing == false)
    }

    @Test("Restore is ignored while a purchase is running")
    func restoreDuringPurchase() async throws {
        let (manager, repository) = makeSUT()
        let gate = AsyncGate()
        repository.purchaseGate = gate

        let purchase = Task { try await manager.purchase(.fixture()) }
        await waitUntil { manager.isPurchasing && gate.waiterCount == 1 }
        let restored = try await manager.restore()
        gate.open()
        _ = try await purchase.value

        #expect(restored == false)
        #expect(repository.restoreCount == 0)
    }

    // MARK: - Products

    @Test("Products start idle")
    func productsIdle() {
        let (manager, _) = makeSUT()

        #expect(manager.products.isIdle)
    }

    @Test("Products go idle, loading, loaded")
    func productsLoaded() async {
        let (manager, repository) = makeSUT()
        let gate = AsyncGate()
        repository.fetchGate = gate
        repository.productsResult = .success([.fixture(id: "w"), .fixture(id: "y", period: .year, price: 39.99)])

        let task = Task { await manager.loadProductsIfNeeded() }
        await waitUntil { manager.products.isLoading }
        gate.open()
        await task.value

        #expect(manager.products.value?.map(\.id) == ["w", "y"])
    }

    @Test("Product loading failure exposes the message")
    func productsFailed() async {
        let (manager, repository) = makeSUT()
        repository.productsResult = .failure(SubscriptionError.productsUnavailable)

        await manager.loadProductsIfNeeded()

        #expect(manager.products.errorMessage == SubscriptionError.productsUnavailable.errorDescription)
    }

    @Test("loadProductsIfNeeded does not refetch loaded products")
    func productsNotRefetched() async {
        let (manager, repository) = makeSUT()
        repository.productsResult = .success([.fixture()])

        await manager.loadProductsIfNeeded()
        await manager.loadProductsIfNeeded()

        #expect(repository.fetchCount == 1)
    }

    @Test("loadProductsIfNeeded does not start a second fetch while loading")
    func productsNotDuplicatedWhileLoading() async {
        let (manager, repository) = makeSUT()
        let gate = AsyncGate()
        repository.fetchGate = gate
        repository.productsResult = .success([.fixture()])

        let first = Task { await manager.loadProductsIfNeeded() }
        await waitUntil { manager.products.isLoading }
        await manager.loadProductsIfNeeded()
        gate.open()
        await first.value

        #expect(repository.fetchCount == 1)
    }

    @Test("loadProductsIfNeeded retries after a failure and reloadProducts always refetches")
    func productsRetry() async {
        let (manager, repository) = makeSUT()
        repository.productsResult = .failure(StubError())
        await manager.loadProductsIfNeeded()
        repository.productsResult = .success([.fixture()])

        await manager.loadProductsIfNeeded()
        await manager.reloadProducts()

        #expect(repository.fetchCount == 3)
        #expect(manager.products.value?.count == 1)
    }
}

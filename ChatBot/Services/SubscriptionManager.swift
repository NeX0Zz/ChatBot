import Combine
import Foundation

/// App-wide subscription state. `isPremium` caches the SDK answer and flips right after a purchase,
/// so locked content opens without restarting the app.
@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var isPremium: Bool
    @Published private(set) var products: Loadable<[SubscriptionProduct]> = .idle
    @Published private(set) var isPurchasing = false

    private let repository: SubscriptionRepository

    init(repository: SubscriptionRepository) {
        self.repository = repository
        isPremium = repository.hasPremiumAccess
        repository.onPremiumAccessChange = { [weak self] isPremium in
            self?.isPremium = isPremium
        }
    }

    var userId: String { repository.userId }

    func start() {
        repository.start()
        isPremium = repository.hasPremiumAccess
    }

    func loadProductsIfNeeded() async {
        if products.value != nil || products.isLoading { return }
        await reloadProducts()
    }

    func reloadProducts() async {
        products = .loading
        do {
            products = .loaded(try await repository.fetchProducts())
        } catch {
            products = .failed(error.localizedDescription)
        }
    }

    /// Returns `true` when the user ends up with premium access.
    func purchase(_ product: SubscriptionProduct) async throws -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        let outcome = try await repository.purchase(product)
        isPremium = repository.hasPremiumAccess
        return outcome == .purchased && isPremium
    }

    func updateAdvertisingIdentifier(_ advertisingId: String?) {
        repository.updateDeviceIdentifiers(advertisingId: advertisingId)
    }

    func paywallShown() {
        repository.paywallShown()
    }

    func paywallClosed() {
        repository.paywallClosed()
    }

    func restore() async throws -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        let restored = try await repository.restorePurchases()
        isPremium = repository.hasPremiumAccess
        guard restored else { throw SubscriptionError.nothingToRestore }
        return restored
    }
}

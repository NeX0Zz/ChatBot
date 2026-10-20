import Foundation
@testable import ChatBot

@MainActor
final class FakeSubscriptionRepository: SubscriptionRepository {
    var userId = "user-1"
    var hasPremiumAccess: Bool
    var onPremiumAccessChange: ((Bool) -> Void)?

    var productsResult: Result<[SubscriptionProduct], Error> = .success([])
    var purchaseResult: Result<PurchaseOutcome, Error> = .success(.purchased)
    var restoreResult: Result<Bool, Error> = .success(true)
    /// Value of `hasPremiumAccess` after a successful purchase call.
    var premiumAfterPurchase = true
    /// Value of `hasPremiumAccess` after a restore call.
    var premiumAfterRestore = true
    var fetchGate: AsyncGate?
    var purchaseGate: AsyncGate?

    private(set) var startCount = 0
    private(set) var fetchCount = 0
    private(set) var purchasedProducts: [SubscriptionProduct] = []
    private(set) var restoreCount = 0
    private(set) var receivedAdvertisingIds: [String?] = []
    private(set) var paywallShownCount = 0
    private(set) var paywallClosedCount = 0

    init(hasPremiumAccess: Bool = false) {
        self.hasPremiumAccess = hasPremiumAccess
    }

    func start() {
        startCount += 1
    }

    func updateDeviceIdentifiers(advertisingId: String?) {
        receivedAdvertisingIds.append(advertisingId)
    }

    func paywallShown() {
        paywallShownCount += 1
    }

    func paywallClosed() {
        paywallClosedCount += 1
    }

    func fetchProducts() async throws -> [SubscriptionProduct] {
        fetchCount += 1
        try await fetchGate?.wait()
        return try productsResult.get()
    }

    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseOutcome {
        purchasedProducts.append(product)
        try await purchaseGate?.wait()
        let outcome = try purchaseResult.get()
        if outcome == .purchased { hasPremiumAccess = premiumAfterPurchase }
        return outcome
    }

    func restorePurchases() async throws -> Bool {
        restoreCount += 1
        try await purchaseGate?.wait()
        let restored = try restoreResult.get()
        hasPremiumAccess = premiumAfterRestore
        return restored
    }
}

extension SubscriptionProduct {
    static func fixture(id: String = "weekly", period: Period = .week, price: Decimal = 4.99) -> SubscriptionProduct {
        SubscriptionProduct(id: id, period: period, price: price, priceLocale: Locale(identifier: "en_US"))
    }
}

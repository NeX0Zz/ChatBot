import Foundation

@MainActor
protocol SubscriptionRepository: AnyObject {
    /// Identifier of the current user, also used as `user_id` for the generation API.
    var userId: String { get }
    var hasPremiumAccess: Bool { get }
    /// Called on the main thread whenever the subscription state changes outside of a purchase call.
    var onPremiumAccessChange: ((Bool) -> Void)? { get set }

    func start()
    func fetchProducts() async throws -> [SubscriptionProduct]
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseOutcome
    func restorePurchases() async throws -> Bool
    /// Attribution identifiers for Apphud; `advertisingId` is present only after the user allowed tracking.
    func updateDeviceIdentifiers(advertisingId: String?)
    /// Paywall analytics for Apphud placements and A/B tests.
    func paywallShown()
    func paywallClosed()
}

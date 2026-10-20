import ApphudSDK
import Foundation
import OSLog
import StoreKit
import UIKit

@MainActor
final class ApphudSubscriptionRepository: NSObject, SubscriptionRepository {
    var onPremiumAccessChange: ((Bool) -> Void)?

    private let apiKey: String
    private let paywallIdentifier: String
    private var productsById: [String: ApphudProduct] = [:]
    private var paywall: ApphudPaywall?
    /// The registered Apphud user; its raw paywalls include ones not attached to any placement.
    private var registeredUser: ApphudUser?
    private var userWaiters: [CheckedContinuation<ApphudUser, Never>] = []
    private let logger = Logger(subsystem: "com.labs.fviu", category: "subscription")

    init(apiKey: String, paywallIdentifier: String) {
        self.apiKey = apiKey
        self.paywallIdentifier = paywallIdentifier
    }

    var userId: String { Apphud.userID() }

    var hasPremiumAccess: Bool { Apphud.hasPremiumAccess() }

    func start() {
        #if DEBUG
        Apphud.enableDebugLogs()
        #endif
        Apphud.start(apiKey: apiKey) { [weak self] user in
            self?.didRegister(user)
        }
        Apphud.setDelegate(self)
        updateDeviceIdentifiers(advertisingId: nil)
    }

    func updateDeviceIdentifiers(advertisingId: String?) {
        Apphud.setDeviceIdentifiers(idfa: advertisingId, idfv: UIDevice.current.identifierForVendor?.uuidString)
    }

    func fetchProducts() async throws -> [SubscriptionProduct] {
        let paywall = try await loadPaywall()
        self.paywall = paywall

        var result: [SubscriptionProduct] = []
        for apphudProduct in paywall.products {
            guard let storeProduct = try await apphudProduct.product(),
                  let product = Self.map(storeProduct) else { continue }
            productsById[product.id] = apphudProduct
            result.append(product)
        }
        guard !result.isEmpty else { throw SubscriptionError.productsUnavailable }
        return result
    }

    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseOutcome {
        guard let apphudProduct = productsById[product.id] else {
            throw SubscriptionError.productsUnavailable
        }
        let result = await Apphud.purchase(apphudProduct)
        if let error = result.error {
            if (error as? SKError)?.code == .paymentCancelled {
                return .cancelled
            }
            logger.error("Purchase failed: \(error.localizedDescription)")
            throw SubscriptionError.purchaseFailed
        }
        notifyAccessChange()
        return Apphud.hasPremiumAccess() ? .purchased : .cancelled
    }

    func restorePurchases() async throws -> Bool {
        if let error = await Apphud.restorePurchases() {
            logger.error("Restore failed: \(error.localizedDescription)")
            throw SubscriptionError.restoreFailed
        }
        notifyAccessChange()
        return Apphud.hasPremiumAccess()
    }

    func paywallShown() {
        guard let paywall else { return }
        Apphud.paywallShown(paywall)
    }

    func paywallClosed() {
        guard let paywall else { return }
        Apphud.paywallClosed(paywall)
    }

    private func loadPaywall() async throws -> ApphudPaywall {
        let (placements, error) = await withCheckedContinuation { continuation in
            Apphud.fetchPlacements { placements, error in
                continuation.resume(returning: (placements, error))
            }
        }
        if let paywall = placements.first(where: { $0.identifier == paywallIdentifier })?.paywall
            ?? placements.compactMap(\.paywall).first(where: { $0.identifier == paywallIdentifier }) {
            return paywall
        }
        // The project's `main` paywall is not attached to any placement, so fall back to the plain paywall list.
        if let paywall = await registeredApphudUser().rawPaywalls().first(where: { $0.identifier == paywallIdentifier }) {
            return paywall
        }

        if let error {
            logger.error("Fetching placements failed: \(error.localizedDescription)")
            if error.networkIssue() { throw APIError.offline }
        }
        logger.error("Paywall \(self.paywallIdentifier) is unavailable")
        throw SubscriptionError.paywallUnavailable
    }

    private func didRegister(_ user: ApphudUser) {
        registeredUser = user
        userWaiters.forEach { $0.resume(returning: user) }
        userWaiters.removeAll()
        notifyAccessChange()
    }

    /// Resolves once Apphud has registered the user, independent of the order of SDK callbacks.
    private func registeredApphudUser() async -> ApphudUser {
        if let registeredUser { return registeredUser }
        return await withCheckedContinuation { userWaiters.append($0) }
    }

    private func notifyAccessChange() {
        onPremiumAccessChange?(Apphud.hasPremiumAccess())
    }

    private static func map(_ product: Product) -> SubscriptionProduct? {
        guard let subscription = product.subscription else { return nil }
        let period: SubscriptionProduct.Period
        switch subscription.subscriptionPeriod.unit {
        case .week: period = .week
        case .month: period = .month
        case .year: period = .year
        default: return nil
        }
        return SubscriptionProduct(
            id: product.id,
            period: period,
            price: product.price,
            priceLocale: product.priceFormatStyle.locale,
            periodCount: subscription.subscriptionPeriod.value
        )
    }
}

extension ApphudSubscriptionRepository: ApphudDelegate {
    nonisolated func apphudSubscriptionsUpdated(_ subscriptions: [ApphudSubscription]) {
        Task { @MainActor in self.notifyAccessChange() }
    }

    nonisolated func apphudNonRenewingPurchasesUpdated(_ purchases: [ApphudNonRenewingPurchase]) {
        Task { @MainActor in self.notifyAccessChange() }
    }
}

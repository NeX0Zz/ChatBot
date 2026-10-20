import Foundation

enum SubscriptionError: LocalizedError {
    case paywallUnavailable
    case productsUnavailable
    case purchaseFailed
    case restoreFailed
    case nothingToRestore

    var errorDescription: String? {
        switch self {
        case .paywallUnavailable, .productsUnavailable:
            String(localized: "Subscription plans are unavailable right now. Please try again later.")
        case .purchaseFailed:
            String(localized: "The purchase could not be completed. Please try again.")
        case .restoreFailed:
            String(localized: "Purchases could not be restored. Please try again.")
        case .nothingToRestore:
            String(localized: "No active subscriptions were found for this Apple ID.")
        }
    }
}

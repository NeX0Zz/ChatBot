/// One rule for paid actions (chat replies, video generations, their retries):
/// premium users pass, everyone else sees the paywall and keeps their input.
@MainActor
final class PremiumGate {
    private let subscriptionManager: SubscriptionManager
    private let router: AppRouter

    init(subscriptionManager: SubscriptionManager, router: AppRouter) {
        self.subscriptionManager = subscriptionManager
        self.router = router
    }

    /// Returns `true` when the action may run; otherwise presents the paywall.
    func allowsPaidAction() -> Bool {
        guard subscriptionManager.isPremium else {
            router.presentPaywall()
            return false
        }
        return true
    }
}

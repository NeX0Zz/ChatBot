import Combine
import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published private(set) var state: Loadable<[PaywallPlan]> = .idle
    @Published var selectedPlanID: String?
    @Published private(set) var isBusy = false
    @Published var alert: AlertMessage?

    private let subscriptionManager: SubscriptionManager
    private var cancellables = Set<AnyCancellable>()

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        subscriptionManager.$products
            .sink { [weak self] in self?.apply($0) }
            .store(in: &cancellables)
        subscriptionManager.$isPurchasing
            .sink { [weak self] in self?.isBusy = $0 }
            .store(in: &cancellables)
    }

    var canPurchase: Bool { selectedPlan != nil && !isBusy }

    private var selectedPlan: PaywallPlan? {
        state.value?.first { $0.id == selectedPlanID }
    }

    func load() async {
        await subscriptionManager.loadProductsIfNeeded()
        if state.value != nil { subscriptionManager.paywallShown() }
    }

    func close() {
        subscriptionManager.paywallClosed()
    }

    func retry() async {
        await subscriptionManager.reloadProducts()
    }

    /// Returns `true` when the user ends up with premium access and the paywall can close.
    func purchaseSelectedPlan() async -> Bool {
        guard let plan = selectedPlan, !isBusy else { return false }
        do {
            return try await subscriptionManager.purchase(plan.product)
        } catch {
            alert = AlertMessage(title: String(localized: "Purchase failed"), message: error.localizedDescription)
            return false
        }
    }

    func restore() async -> Bool {
        guard !isBusy else { return false }
        do {
            return try await subscriptionManager.restore()
        } catch {
            alert = AlertMessage(title: String(localized: "Restore failed"), message: error.localizedDescription)
            return false
        }
    }

    private func apply(_ products: Loadable<[SubscriptionProduct]>) {
        switch products {
        case .idle:
            state = .idle
        case .loading:
            state = .loading
        case let .loaded(items):
            let plans = PaywallPlan.makePlans(from: items)
            state = .loaded(plans)
            if !plans.contains(where: { $0.id == selectedPlanID }) {
                selectedPlanID = plans.first?.id
            }
        case let .failed(message):
            state = .failed(message)
        }
    }
}

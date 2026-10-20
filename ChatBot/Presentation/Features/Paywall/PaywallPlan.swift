import Foundation

/// A purchasable plan prepared for display: all prices come from the store product, never hardcoded.
struct PaywallPlan: Identifiable, Equatable {
    let product: SubscriptionProduct
    let periodName: String
    let weeklyPrice: String
    let fullPrice: String
    let savePercent: Int?

    var id: String { product.id }

    /// Plans ordered from the longest period; the longest one gets a discount badge against the shortest.
    static func makePlans(from products: [SubscriptionProduct]) -> [PaywallPlan] {
        let sorted = products.sorted { $0.period.rank > $1.period.rank }
        let baseline = sorted.last
        return sorted.map { product in
            PaywallPlan(
                product: product,
                periodName: product.period.displayName,
                weeklyPrice: format(product.pricePerWeek, locale: product.priceLocale),
                fullPrice: format(product.price, locale: product.priceLocale),
                savePercent: product == sorted.first ? savings(of: product, against: baseline) : nil
            )
        }
    }

    private static func savings(of product: SubscriptionProduct, against baseline: SubscriptionProduct?) -> Int? {
        guard let baseline, baseline != product, baseline.pricePerWeek > 0 else { return nil }
        let ratio = (product.pricePerWeek / baseline.pricePerWeek) as NSDecimalNumber
        let percent = Int(((1 - ratio.doubleValue) * 100).rounded())
        return percent > 0 ? percent : nil
    }

    private static func format(_ value: Decimal, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }
}

private extension SubscriptionProduct.Period {
    var rank: Int {
        switch self {
        case .week: 0
        case .month: 1
        case .year: 2
        }
    }

    var displayName: String {
        switch self {
        case .week: String(localized: "Week")
        case .month: String(localized: "Month")
        case .year: String(localized: "Year")
        }
    }
}

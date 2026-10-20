import Foundation

struct SubscriptionProduct: Identifiable, Hashable, Sendable {
    enum Period: Sendable {
        case week
        case month
        case year
    }

    let id: String
    let period: Period
    let price: Decimal
    let priceLocale: Locale
    /// Number of `period` units, e.g. 3 for a quarterly plan.
    var periodCount = 1

    var weeksInPeriod: Decimal {
        let weeksPerUnit: Decimal
        switch period {
        case .week: weeksPerUnit = 1
        case .month: weeksPerUnit = Decimal(52) / Decimal(12)
        case .year: weeksPerUnit = 52
        }
        return weeksPerUnit * Decimal(periodCount)
    }

    var pricePerWeek: Decimal { price / weeksInPeriod }
}

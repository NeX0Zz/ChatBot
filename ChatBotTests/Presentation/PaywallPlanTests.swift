import Foundation
import Testing
@testable import ChatBot

@Suite("PaywallPlan")
struct PaywallPlanTests {
    private let week = SubscriptionProduct.fixture(id: "week", period: .week, price: 4.99)
    private let month = SubscriptionProduct.fixture(id: "month", period: .month, price: 12.99)
    private let year = SubscriptionProduct.fixture(id: "year", period: .year, price: 39.99)

    @Test("Plans are ordered from the longest period")
    func ordering() {
        let plans = PaywallPlan.makePlans(from: [week, year, month])

        #expect(plans.map(\.id) == ["year", "month", "week"])
    }

    @Test("Empty products give no plans")
    func empty() {
        #expect(PaywallPlan.makePlans(from: []).isEmpty)
    }

    @Test("A single product has no discount badge")
    func single() {
        let plans = PaywallPlan.makePlans(from: [week])

        #expect(plans.count == 1)
        #expect(plans.first?.savePercent == nil)
    }

    @Test("Only the longest plan carries the saving against the shortest")
    func savePercent() {
        let plans = PaywallPlan.makePlans(from: [week, month, year])

        let expected = Int(((1 - (39.99 / 52) / 4.99) * 100).rounded())
        #expect(plans.first?.savePercent == expected)
        #expect(plans.dropFirst().allSatisfy { $0.savePercent == nil })
    }

    @Test("No badge when the longest plan is not cheaper per week")
    func noSavings() {
        let expensiveYear = SubscriptionProduct.fixture(id: "year", period: .year, price: 400)

        let plans = PaywallPlan.makePlans(from: [week, expensiveYear])

        #expect(plans.first?.savePercent == nil)
    }

    @Test("Prices are formatted in the product locale")
    func formatting() {
        let euro = SubscriptionProduct(id: "w", period: .week, price: 4.5, priceLocale: Locale(identifier: "de_DE"))

        let plan = PaywallPlan.makePlans(from: [euro])[0]

        #expect(plan.fullPrice.contains("4,50"))
        #expect(plan.fullPrice.contains("€"))
        #expect(plan.weeklyPrice == plan.fullPrice)
    }

    @Test("Weekly price of a longer plan comes from the per-week calculation")
    func weeklyPrice() {
        let plans = PaywallPlan.makePlans(from: [year])

        #expect(plans[0].weeklyPrice.contains("0.77"))
        #expect(plans[0].fullPrice.contains("39.99"))
    }

    @Test("Multi-period products spread the price over all units")
    func periodCount() {
        var quarter = SubscriptionProduct.fixture(id: "quarter", period: .month, price: 39)
        quarter.periodCount = 3

        let plan = PaywallPlan.makePlans(from: [quarter])[0]

        #expect(plan.weeklyPrice.contains("3.00"))
    }

    @Test("Plan id and period names come from the product")
    func identity() {
        let plans = PaywallPlan.makePlans(from: [week, month, year])

        #expect(plans.map(\.product) == [year, month, week])
        #expect(plans.allSatisfy { !$0.periodName.isEmpty })
    }
}

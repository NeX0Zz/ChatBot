import Foundation
import Testing
@testable import ChatBot

@Suite("SubscriptionProduct")
struct SubscriptionProductTests {
    private func assertClose(_ value: Decimal, to expected: Double, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(abs(NSDecimalNumber(decimal: value).doubleValue - expected) < 0.0001, sourceLocation: sourceLocation)
    }

    @Test("Weekly price is the price itself")
    func week() {
        let product = SubscriptionProduct.fixture(period: .week, price: 4.99)

        #expect(product.pricePerWeek == 4.99)
        #expect(product.weeksInPeriod == 1)
    }

    @Test("Monthly price is spread over 52/12 weeks")
    func month() {
        let product = SubscriptionProduct.fixture(period: .month, price: 13)

        assertClose(product.pricePerWeek, to: 3.0)
    }

    @Test("Yearly price is spread over 52 weeks")
    func year() {
        let product = SubscriptionProduct.fixture(period: .year, price: 52)

        assertClose(product.pricePerWeek, to: 1.0)
        #expect(product.weeksInPeriod == 52)
    }

    @Test("Real-world yearly price")
    func realisticYear() {
        assertClose(SubscriptionProduct.fixture(period: .year, price: 39.99).pricePerWeek, to: 39.99 / 52)
    }

    @Test("Zero price stays zero for every period", arguments: [SubscriptionProduct.Period.week, .month, .year])
    func zero(period: SubscriptionProduct.Period) {
        #expect(SubscriptionProduct.fixture(period: period, price: 0).pricePerWeek == 0)
    }

    @Test("Longer periods are cheaper per week for the same price")
    func ordering() {
        let week = SubscriptionProduct.fixture(period: .week, price: 10).pricePerWeek
        let month = SubscriptionProduct.fixture(period: .month, price: 10).pricePerWeek
        let year = SubscriptionProduct.fixture(period: .year, price: 10).pricePerWeek

        #expect(week > month)
        #expect(month > year)
    }

    @Test("Period count multiplies the number of weeks")
    func periodCount() {
        var quarter = SubscriptionProduct.fixture(period: .month, price: 39)
        quarter.periodCount = 3
        var biweekly = SubscriptionProduct.fixture(period: .week, price: 10)
        biweekly.periodCount = 2

        assertClose(quarter.weeksInPeriod, to: 52.0 / 4)
        assertClose(quarter.pricePerWeek, to: 3.0)
        #expect(biweekly.weeksInPeriod == 2)
        #expect(biweekly.pricePerWeek == 5)
    }

    @Test("Period count defaults to one")
    func periodCountDefault() {
        #expect(SubscriptionProduct.fixture().periodCount == 1)
    }
}

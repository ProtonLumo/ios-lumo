import Foundation
import Testing

@testable import LumoApp

struct PlanOptionViewModelTests {
    @Test
    func yearlyPlan() {
        let yearlyPlan = ComposedPlan.testData(
            id: "<yearly_id_1>",
            cycle: 12,
            pricePerMonth: 119.99,
            displayPrice: "$119.88"
        )
        let discountAmount: Decimal = 3589.0
        let sut = PlanOptionViewModel(plan: yearlyPlan, discount: discountAmount)

        #expect(sut.id == yearlyPlan.product.id)
        #expect(sut.title == String(localized: "app.payment.duration.yearly"))
        #expect(sut.subtitle == "$9.00/month")
        #expect(sut.displayPrice == yearlyPlan.product.displayPrice)
        #expect(sut.discount == "Save $35.89")
        #expect(sut.type == .year)
        #expect(sut.isSelected == true)
    }

    @Test
    func monthlyPlan() {
        let monthlyPlan = ComposedPlan.testData(
            id: "<monthly_id_2>",
            cycle: 1,
            pricePerMonth: 12.99,
            displayPrice: "$12.99"
        )
        let sut = PlanOptionViewModel(plan: monthlyPlan, discount: 0)

        #expect(sut.id == monthlyPlan.product.id)
        #expect(sut.title == String(localized: "app.payment.duration.monthly"))
        #expect(sut.subtitle == "$12.00/month")
        #expect(sut.displayPrice == monthlyPlan.product.displayPrice)
        #expect(sut.discount == nil)
        #expect(sut.type == .month)
        #expect(sut.isSelected == false)
    }

    @Test
    func invalidPlan() {
        let invalid = ComposedPlan.testData(
            id: "<error>",
            cycle: 0,
            pricePerMonth: 10,
            displayPrice: "$100"
        )
        let sut = PlanOptionViewModel(plan: invalid, discount: 0)

        #expect(sut.id == invalid.product.id)
        #expect(sut.title == String(localized: "app.payment.error"))
        #expect(sut.subtitle == String(localized: "app.payment.error"))
        #expect(sut.displayPrice == invalid.product.displayPrice)
        #expect(sut.discount == nil)
        #expect(sut.type == .month)
        #expect(sut.isSelected == false)
    }
}

private struct ProductStub: ProductProtocol {
    let id: String
    let price: Decimal
    let displayPrice: String
    let stubbedCurrency: String

    func currency() -> String {
        stubbedCurrency
    }
}

fileprivate extension ComposedPlan {
    static func testData(
        id: String = "test_plan",
        cycle: Int,
        pricePerMonth: Decimal,
        currency: String = "USD",
        displayPrice: String = "$119.88"
    ) -> ComposedPlan {
        ComposedPlan(
            plan: .init(
                description: .none,
                instances: [
                    .init(
                        price: [
                            Price(current: 1299, currency: "EUR", id: "<price_id_1>"),
                            Price(current: 1299, currency: "USD", id: "<price_id_2>"),
                            Price(current: 1299, currency: "CHF", id: "<price_id_3>"),
                        ],
                        description: "Per month",
                        cycle: 1,
                        periodEnd: 1_772_804_061,
                        vendors: .init(apple: .none)
                    ),
                    .init(
                        price: [
                            Price(current: 11988, currency: "EUR", id: "<price_id_1>"),
                            Price(current: 11988, currency: "USD", id: "<price_id_2>"),
                            Price(current: 11988, currency: "CHF", id: "<price_id_3>"),
                        ],
                        description: "Per year",
                        cycle: 12,
                        periodEnd: 1_801_920_861,
                        vendors: .init(apple: .none)
                    ),
                ],
                name: "__NOT_USED__",
                state: 1,
                type: 1,
                title: "__NOT_USED__",
                features: 0,
                entitlements: [],
                decorations: [],
                id: id,
                services: 0
            ),
            instance: .init(
                price: [],
                description: "__NOT_USED__",
                cycle: cycle,
                periodEnd: 1_772_804_061,
                vendors: .init(apple: .none)
            ),
            product: ProductStub(
                id: id,
                price: pricePerMonth,
                displayPrice: "\(pricePerMonth)",
                stubbedCurrency: currency
            )
        )
    }
}

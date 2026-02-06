import Foundation
import Testing

@testable import LumoApp

struct PlanOptionViewModelTests {
    struct Expected {
        let title: String
        let subtitle: String
        let discount: String?
        let type: PlanType
        let isSelected: Bool
    }

    struct TestCase {
        let given: (plan: ComposedPlan, discountAmount: Decimal)
        let expected: Expected
    }

    @Test(arguments: [
        TestCase(
            given: (
                plan: .testData(id: "<id_1>", cycle: 12, price: 119.99, displayPrice: "$119.88"),
                discountAmount: 3589
            ),
            expected: .init(
                title: String(localized: "app.payment.duration.yearly"),
                subtitle: "$10.00/month",
                discount: "Save $35.89",
                type: .year,
                isSelected: true
            )
        ),
        TestCase(
            given: (
                plan: .testData(id: "<id_2>", cycle: 1, price: 12.99, displayPrice: "$12.99"),
                discountAmount: 0
            ),
            expected: .init(
                title: String(localized: "app.payment.duration.monthly"),
                subtitle: "$12.99/month",
                discount: nil,
                type: .month,
                isSelected: false
            )
        ),
        TestCase(
            given: (
                plan: .testData(id: "<id_3>", cycle: 0, price: 10, displayPrice: "$100"),
                discountAmount: 0
            ),
            expected: .init(
                title: String(localized: "app.payment.error"),
                subtitle: String(localized: "app.payment.error"),
                discount: nil,
                type: .month,
                isSelected: false
            )
        ),
    ])
    func planHasCorrectDisplayData(testCase: TestCase) {
        let sut = PlanOptionViewModel(
            plan: testCase.given.plan,
            discount: testCase.given.discountAmount
        )

        #expect(sut.id == testCase.given.plan.product.id)
        #expect(sut.title == testCase.expected.title)
        #expect(sut.subtitle == testCase.expected.subtitle)
        #expect(sut.displayPrice == testCase.given.plan.product.displayPrice)
        #expect(sut.discount == testCase.expected.discount)
        #expect(sut.type == testCase.expected.type)
        #expect(sut.isSelected == testCase.expected.isSelected)
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
        price: Decimal,
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
                price: price,
                displayPrice: displayPrice,
                stubbedCurrency: currency
            )
        )
    }
}

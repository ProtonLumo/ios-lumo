import Foundation
import StoreKit

public struct ComposedPlan: Equatable, Hashable, Sendable {

    public let plan: AvailablePlan
    public let instance: PlanInstance
    public let product: any ProductProtocol

    private static let minimumVisibleDiscount = 5

    public init(plan: AvailablePlan, instance: PlanInstance, product: any ProductProtocol) {
        self.plan = plan
        self.instance = instance
        self.product = product
    }

    public var pricePerMonth: Double {
        switch instance.cycle {
        case 1, 12:
            return (NSDecimalNumber(decimal: product.price).doubleValue / Double(instance.cycle)) / 100
        default:
            debugPrint("\(instance.cycle) cycle not supported")
            return 0
        }
    }

    public func discount(comparedTo plan: ComposedPlan) -> Int? {
        let pricePerMonthCurrentPlan: Double = pricePerMonth
        let pricePerMonthComparedPlan: Double = plan.pricePerMonth

        guard pricePerMonthComparedPlan != 0 else { return nil }
        guard pricePerMonthCurrentPlan != 0 else { return 100 }
        let discountDouble = (1 - (pricePerMonthCurrentPlan / pricePerMonthComparedPlan)) * 100
        // don't round to 100% if it's not exactly 100%
        let discountInt = min(Int(discountDouble.rounded()), 99)
        return discountInt >= Self.minimumVisibleDiscount ? discountInt : nil
    }

    public func formattedPrice(amount: Double, currency: String) -> String {
        return Decimal(amount / 100).formatted(.currency(code: currency).presentation(.narrow).rounded())
    }
}

extension ComposedPlan {
    public static func == (lhs: ComposedPlan, rhs: ComposedPlan) -> Bool {
        lhs.plan == rhs.plan &&
        lhs.instance == rhs.instance
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(plan.id)
        hasher.combine(product.id)
    }
}

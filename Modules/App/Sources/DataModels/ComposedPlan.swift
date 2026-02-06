import Foundation
import StoreKit

struct ComposedPlan: Equatable, Hashable, Sendable {
    let plan: AvailablePlan
    let instance: PlanInstance
    let product: any ProductProtocol

    private static let minimumVisibleDiscount = 5

    init(plan: AvailablePlan, instance: PlanInstance, product: any ProductProtocol) {
        self.plan = plan
        self.instance = instance
        self.product = product
    }

    var pricePerMonth: Double {
        switch instance.cycle {
        case 1, 12:
            return (NSDecimalNumber(decimal: product.price).doubleValue / Double(instance.cycle)) / 100
        default:
            debugPrint("\(instance.cycle) cycle not supported")
            return 0
        }
    }

    func discount(comparedTo plan: ComposedPlan) -> Int? {
        let pricePerMonthCurrentPlan: Double = pricePerMonth
        let pricePerMonthComparedPlan: Double = plan.pricePerMonth

        guard pricePerMonthComparedPlan != 0 else { return nil }
        guard pricePerMonthCurrentPlan != 0 else { return 100 }
        let discountDouble = (1 - (pricePerMonthCurrentPlan / pricePerMonthComparedPlan)) * 100
        // don't round to 100% if it's not exactly 100%
        let discountInt = min(Int(discountDouble.rounded()), 99)
        return discountInt >= Self.minimumVisibleDiscount ? discountInt : nil
    }
}

extension ComposedPlan {
    public static func == (lhs: ComposedPlan, rhs: ComposedPlan) -> Bool {
        lhs.plan == rhs.plan && lhs.instance == rhs.instance
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(plan.id)
        hasher.combine(product.id)
    }
}

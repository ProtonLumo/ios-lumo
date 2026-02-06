import Foundation
import ProtonUIFoundations

class PlanOptionViewModel: ObservableObject, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let displayPrice: String
    let discount: String?
    let type: PlanType
    let plan: ComposedPlan

    @Published var isSelected: Bool = false

    init(plan: ComposedPlan, discount: Decimal) {
        self.id = plan.product.id
        self.displayPrice = plan.product.displayPrice
        self.plan = plan

        let title: String
        let subtitle: String
        let formattedDiscount: String?
        let type: PlanType
        let isPlanSelected: Bool

        switch plan.instance.cycle {
        case 12:
            title = String(localized: "app.payment.duration.yearly")
            type = .year
            subtitle = plan.formattedMonthlyPrice
            let value: Decimal = discount / 100.0
            let discount = value.formattedPrice(currencyCode: plan.product.currency())
            formattedDiscount = [String(localized: "app.payment.save.prefix"), discount].joined()
            isPlanSelected = true
        case 1:
            title = String(localized: "app.payment.duration.monthly")
            subtitle = plan.formattedMonthlyPrice
            formattedDiscount = nil
            type = .month
            isPlanSelected = false
        default:
            title = String(localized: "app.payment.error")
            subtitle = String(localized: "app.payment.error")
            type = .month
            formattedDiscount = nil
            isPlanSelected = false
        }

        self.title = title
        self.subtitle = subtitle
        self.discount = formattedDiscount
        self.type = type
        self.isSelected = isPlanSelected
    }

    func setSelected(_ value: Bool) {
        DispatchQueue.main.async {
            self.isSelected = value
        }
    }
}

fileprivate extension ComposedPlan {
    var formattedMonthlyPrice: String {
        let monthlyPrice = Decimal(pricePerMonth * 100)
        let formattedPrice = monthlyPrice.formattedPrice(currencyCode: product.currency())

        return [formattedPrice, String(localized: "app.payment.month.suffix")].joined()
    }
}

extension PlanOptionViewModel: Equatable {
    static func == (lhs: PlanOptionViewModel, rhs: PlanOptionViewModel) -> Bool {
        lhs.title == rhs.title && lhs.subtitle == rhs.subtitle && lhs.displayPrice == rhs.plan.product.displayPrice && lhs.discount == rhs.discount && lhs.type == rhs.type
    }
}

import Foundation
import ProtonUIFoundations

class PlanOptionViewModel: ObservableObject, Identifiable {
    let id: String
    let title: String
    let subTitle: String
    let price: String
    let discount: String?
    let type: PlanType
    public let plan: ComposedPlan

    @Published var isSelected: Bool = false

    public init(plan: ComposedPlan, discount: Double) {

        self.plan = plan

        switch plan.instance.cycle {
        case 12:
            self.title = String(localized: "app.payment.duration.yearly")
            self.type = .year
            let monthlyPriceFromStoreKit = plan.pricePerMonth
            self.subTitle = Decimal(Int(monthlyPriceFromStoreKit * 100)).formatted(.currency(code: plan.product.currency()).presentation(.narrow).rounded()) + String(localized: "app.payment.month.suffix")
            self.discount = String(localized: "app.payment.save.prefix") + plan.formattedPrice(amount: discount,
                                                          currency: plan.product.currency())
            self.isSelected = true
        case 1:
            self.title = String(localized: "app.payment.duration.monthly")
            self.type = .month
            let monthlyPriceFromStoreKit = plan.pricePerMonth
            
            self.subTitle = Decimal(Int(monthlyPriceFromStoreKit * 100)).formatted(.currency(code: plan.product.currency()).presentation(.narrow).rounded()) + String(localized: "app.payment.month.suffix")
            self.discount = nil
            self.isSelected = false
        default:
            self.title = String(localized: "app.payment.error")
            self.subTitle = String(localized: "app.payment.error")
            self.type = .month
            self.discount = nil
            self.isSelected = false
        }
        self.price = plan.product.displayPrice

        self.id = plan.product.id
    }

    public func setSelected(_ value: Bool) {
        DispatchQueue.main.async {
            self.isSelected = value
        }
    }
}

extension PlanOptionViewModel: Equatable {

    static func == (lhs: PlanOptionViewModel, rhs: PlanOptionViewModel) -> Bool {
        lhs.title == rhs.title &&
        lhs.subTitle == rhs.subTitle &&
        lhs.price == rhs.plan.product.displayPrice &&
        lhs.discount == rhs.discount &&
        lhs.type == rhs.type
    }
}

import SwiftUI
import ProtonUIFoundations

struct PlanOption: View {

    @ObservedObject var model: PlanOptionViewModel
    private let brandPurple: Color = Theme.color.iconAccent

    var body: some View {
        HStack {
            Circle()
                .stroke(model.isSelected ? brandPurple : Color.gray, lineWidth: 2)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .fill(model.isSelected ? brandPurple : Color.clear)
                        .frame(width: 16, height: 16)
                )

            VStack(alignment: .leading) {
                Text(model.title)
                    .font(.headline)
                    .foregroundColor(Theme.color.textNorm)
            }
            Spacer()
            VStack(alignment: .trailing) {
                
                if((model.discount ?? "") != "") {
                    Text(model.price)
                        .foregroundColor(brandPurple)
                    Text(model.discount ?? "")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text(model.price)
                        .foregroundColor(brandPurple)
                }

            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(model.isSelected ? brandPurple : Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}

#if DEBUG
private struct MockProduct: ProductProtocol {
    var displayName: String = "Lumo Monthly"
    var description: String = "Monthly subscription for Lumo."
    var displayPrice: String = "$9.99"
    var price: Decimal = 999
    var id: String = "ioslumo_lumo2024_1_usd_auto_renewing"
    func currency() -> String { "USD" }
}

#Preview {
    let mockPrice = Price(current: 999, currency: "USD", id: "price_id_1")
    let mockVendors = Vendors(apple: Vendor(productID: "ioslumo_lumo2024_1_usd_auto_renewing", customerID: nil))
    let mockInstance = PlanInstance(
        price: [mockPrice],
        description: "Per month",
        cycle: 1,
        periodEnd: 1758194800,
        vendors: mockVendors
    )
    let mockPlan = AvailablePlan(
        description: "Lumo monthly plan",
        instances: [mockInstance],
        name: "lumo2024",
        state: 0,
        type: 1,
        title: "Lumo Monthly",
        features: 0,
        entitlements: PreviewsData.descriptionEntitlements(),
        decorations: [],
        id: "lumo2024",
        services: 0
    )
    let mockProduct = MockProduct()
    let composedPlan = ComposedPlan(plan: mockPlan, instance: mockInstance, product: mockProduct)
    let viewModel = PlanOptionViewModel(plan: composedPlan, discount: 0.99)
    PlanOption(model: viewModel)
}
#endif

import LumoDesignSystem
import LumoUI
import ProtonUIFoundations
import SwiftUI

struct PlanOption: View {
    @ObservedObject var model: PlanOptionViewModel
    @EnvironmentObject private var themeProvider: ThemeProvider
    var isPromotionOffer: Bool = false

    private let brandPurple: Color = Theme.color.iconAccent
    private let brandOrange: Color = Color(hex: 0xFFAC2E)
    private let promoYellow: Color = Color(red: 1.0, green: 0.8, blue: 0.0)

    var body: some View {
        let isYearly = model.type == .year

        ZStack(alignment: .topTrailing) {
            // Main card content
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    // Radio button
                    Circle()
                        .stroke(model.isSelected ? brandPurple : (themeProvider.isDarkMode ? Color.gray.opacity(0.8) : Color.gray), lineWidth: 2)
                        .square(size: 24)
                        .overlay(
                            Circle()
                                .fill(model.isSelected ? brandPurple : Color.clear)
                                .square(size: 16)
                        )
                        .padding(.top, isYearly ? 2 : 0)

                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(model.title)
                                .font(.headline)
                                .foregroundColor(themeProvider.textColor)

                            // "Best Value" badge for yearly with promo
                            if isYearly {
                                Text(String(localized: "app.payment.bestValue"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(brandOrange)
                                    .cornerRadius(4)
                            }
                        }

                        if !model.subtitle.isEmpty {
                            Text(model.subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(themeProvider.secondaryTextColor)
                        }
                    }

                    Spacer()

                    // Price section
                    VStack(alignment: .trailing, spacing: 4) {
                        if let discount = model.discount, !discount.isEmpty {
                            Text(model.displayPrice)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(brandPurple)

                            Text(discount)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isYearly ? brandOrange : .green)
                        } else {
                            Text(model.displayPrice)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(brandPurple)
                        }
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DS.Color.Background.norm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isYearly && model.isSelected ? brandOrange : model.isSelected ? brandPurple : (themeProvider.isDarkMode ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)),
                        lineWidth: isYearly && model.isSelected ? 3 : 2
                    )
            )
        }
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
            periodEnd: 1_758_194_800,
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

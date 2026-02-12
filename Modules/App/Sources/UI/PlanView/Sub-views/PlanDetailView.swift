import LumoUI
import ProtonUIFoundations
import SwiftUI

struct PlanDetailView: View {
    private struct Constants {
        static let iconSize: CGFloat = 15
        static let entitlementTextVerticalOffset: CGFloat = -3
        static let entitlementTextSize: CGFloat = 14
        static let entitlementFontWeight: Font.Weight = .regular
    }

    @StateObject var viewModel: PlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.standard) {
            ForEach(viewModel.descriptionEntitlements, id: \.self) { entitlement in
                HStack(alignment: .top) {
                    FallbackAsyncImage(
                        url: viewModel.iconURLforEntitlement(entitlement),
                        fallbackImage: Theme.icon.checkmark
                    )
                    .foregroundColor(Theme.color.iconAccent)
                    .square(size: Constants.iconSize)
                    Text(entitlement.text)
                        .font(.system(size: Constants.entitlementTextSize))
                        .fontWeight(Constants.entitlementFontWeight)
                        .padding(.top, Constants.entitlementTextVerticalOffset)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

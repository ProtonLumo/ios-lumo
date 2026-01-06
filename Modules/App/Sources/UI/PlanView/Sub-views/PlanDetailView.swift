import SwiftUI
import ProtonUIFoundations

struct PlanDetailView: View {

    private struct Constants {
        static let iconSize: CGFloat = 15
        static let buttonTopPadding: CGFloat = 10
        static let entitlementTextVerticalOffset: CGFloat = -3
        static let entitlementTextSize: CGFloat = 14
        static let entitlementFontWeight: Font.Weight = .regular
    }

    @StateObject var viewModel: PlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.standard) {
            ForEach(viewModel.descriptionEntitlements, id: \.self) { entitlement in
                HStack(alignment: .top) {
                    PCAsyncImage(url: viewModel.iconURLforEntitlement(entitlement),
                                 placeholderImage: Theme.icon.checkmark) { image in
                        image
                            .resizable()
                            .renderingMode(.template)
                    } placeholder: {
                        ProgressView()
                    }
                    .foregroundColor(Theme.color.iconAccent)
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
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

// #Preview {
//    PlanDetailView()
// }

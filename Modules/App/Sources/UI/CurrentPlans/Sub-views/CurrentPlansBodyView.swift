import ProtonUIFoundations
import SwiftUI

struct CurrentPlansBodyView: View {

    @ObservedObject var viewModel: CurrentPlansViewModel

    var body: some View {

        VStack {
            // MARK: Current plans
            ScrollView(showsIndicators: false) {
                ForEach(viewModel.currentPlans, id: \.id) { viewModel in
                    PlanView(viewModel: viewModel)
                        .padding(.top, Theme.spacing.standard)
                }

                FooterView(image: Theme.icon.infoCircle,
                           text: String(localized: "current.plans.manage.subscription.message"))
            }
            .padding(.horizontal, Theme.spacing.medium)
            .padding(.bottom, viewModel.bottomPadding)
        }
    }
}

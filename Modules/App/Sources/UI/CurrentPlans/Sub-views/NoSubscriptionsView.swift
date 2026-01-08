import SwiftUI
import ProtonUIFoundations

struct NoSubscriptionsView: View {

    var body: some View {
        ZStack {
            Color(Theme.color.backgroundNorm)
                .ignoresSafeArea()
            VStack {
                Image("NoData")
                Text(String(localized: "current.plans.no.data.title"))
                    .font(.headline)
                    .padding(.top, Theme.spacing.extraLarge)
                Text(String(localized: "current.plans.manage.subscription.message"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.spacing.large)
            }
            .padding(Theme.spacing.large)
        }
    }
}

#Preview {
    NoSubscriptionsView()
}

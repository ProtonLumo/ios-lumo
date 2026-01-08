import SwiftUI
import ProtonUIFoundations

struct ErrorView: View {

    let buttonAction: @Sendable () -> Void

    var body: some View {
        ZStack {
            Color(Theme.color.backgroundNorm)
                .ignoresSafeArea()

            VStack {
                Image("ErrorImage")
                Text(String(localized: "current.plans.error.title"))
                    .font(.headline)
                    .padding(.top, Theme.spacing.extraLarge)
                Text(String(localized: "current.plans.error.message"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.spacing.large)
            }
            .padding(Theme.spacing.large)
        }
    }
}

#Preview {
    ErrorView(buttonAction: {})
}

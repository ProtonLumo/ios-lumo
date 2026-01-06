import SwiftUI
import ProtonUIFoundations

struct SubscriptionLoadingView: View {

    let loadingMessage: String

    var body: some View {
        ZStack {
            Color(Theme.color.backgroundNorm)
                .ignoresSafeArea()

            VStack {
                Spacer()
                ProgressView(loadingMessage)
                    .tint(Theme.color.iconAccent)
                Spacer()
            }
        }
    }
}

#Preview {
    SubscriptionLoadingView(loadingMessage: "Loading plans...")
}

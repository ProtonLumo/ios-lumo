import SwiftUI
import ProtonUIFoundations

struct FooterView: View {

    let image: Image
    let text: String

    private struct Constants {
        static let horizontalSpacing: CGFloat = Theme.spacing.standard
        static let iconSize: CGSize = CGSize(width: 16, height: 16)
    }

    var body: some View {
        HStack(spacing: Constants.horizontalSpacing) {
            image
                .resizable()
                .frame(width: Constants.iconSize.width, height: Constants.iconSize.height)
                .foregroundColor(Theme.color.shade80)
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.color.shade80)
            Spacer()
        }
    }
}

#Preview {
    FooterView(image: Theme.icon.infoCircle,
               text: String(localized: "current.plans.manage.subscription.message"))
}

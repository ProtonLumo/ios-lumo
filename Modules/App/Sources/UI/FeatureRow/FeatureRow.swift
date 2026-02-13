import LumoDesignSystem
import LumoUI
import ProtonUIFoundations
import SwiftUI

struct FeatureRow: View {
    let model: FeatureRowModel

    private struct Constants {
        static var iconSize: CGFloat = 15
        static var valueColumnWidth: CGFloat = 75
    }

    var body: some View {
        HStack {
            FallbackAsyncImage(
                url: model.iconURL,
                fallbackImage: Theme.icon.checkmark
            )
            .foregroundColor(Theme.color.iconAccent)
            .square(size: Constants.iconSize)

            Text(model.title)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.norm)

            Text(model.plus)
                .font(.system(size: 14))
                .frame(width: Constants.valueColumnWidth, alignment: .center)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.norm)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    let model = FeatureRowModel(
        icon: "bubble.left",
        text: "Daily chats::Limited::Unlimited"
    )

    FeatureRow(model: model)
}

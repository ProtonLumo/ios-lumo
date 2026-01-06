import SwiftUI
import ProtonUIFoundations

struct PlanDetailHeaderView: View {

    @Binding var isExpanded: Bool

    let title: String
    let description: String
    let formattedPrice: String
    let formattedPeriod: String
    let decorationsURLs: [URL]?

    private struct Constants {

        static let buttonTopPadding: CGFloat = 10
        static let chevronSize: CGFloat = 20
        static let imageTouchArea: CGFloat = 5

        static let priceTextFont: Font = .headline
        static let periodTextFont: Font = .caption

        static func imageRotationAngle(isExpanded: Bool) -> Double {
            return isExpanded ? 180 : 0
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            HeaderTitleView(title: title,
                            description: description,
                            decorations: decorationsURLs)
            Spacer()
            VStack(alignment: .trailing) {
                Text(formattedPrice)
                    .font(Constants.priceTextFont)
                Text(formattedPeriod)
                    .font(Constants.periodTextFont)
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .frame(width: Constants.chevronSize, height: Constants.chevronSize)
                        .padding(Constants.imageTouchArea)
                        .rotationEffect(.degrees(Constants.imageRotationAngle(isExpanded: isExpanded)))
                }
                .foregroundColor(Theme.color.iconAccent)
                .padding(.top, Constants.buttonTopPadding)
            }
        }
    }
}

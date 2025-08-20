import SwiftUI
import ProtonUIFoundations

public struct HeaderTitleView: View {

    private struct Constants {
        static let decorationSize: CGFloat = 16

        static let titleTextSize: CGFloat = 17
        static let titleFontWeight: Font.Weight = .semibold

        static let descriptionTextSize: CGFloat = 13
        static let descriptionFontWeight: Font.Weight = .regular
    }

    let title: String
    let description: String
    let decorations: [URL]?

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing.standard) {
            HStack {
                Text(title)
                    .font(.system(size: Constants.titleTextSize))
                    .fontWeight(Constants.titleFontWeight)
                    .foregroundColor(Theme.color.textAccent)
                if let decorationsUrl = decorations {
                    ForEach(decorationsUrl, id: \.self) { decoration in
                        PCAsyncImage(url: decoration, placeholderImage: nil) { image in
                            image
                                .resizable()
                                .renderingMode(.template)
                        } placeholder: {
                            ProgressView()
                        }
                        .foregroundColor(Theme.color.iconAccent)
                        .frame(width: Constants.decorationSize, height: Constants.decorationSize)
                    }
                }
            }
            Text(description)
                .font(.system(size: Constants.descriptionTextSize))
                .fontWeight(Constants.descriptionFontWeight)
                .foregroundColor(Theme.color.textWeak)
        }
    }
}

// #Preview {
//    HeaderTitleView()
// }

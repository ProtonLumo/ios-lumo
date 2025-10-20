import SwiftUI
import ProtonUIFoundations

struct FeatureRow: View {
    let model: FeatureRowModel
    @Environment(\.colorScheme) private var colorScheme
    
    private struct Constants {
        static var iconSize: CGFloat = 15
        static var valueColumnWidth: CGFloat = 75
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        HStack {
            PCAsyncImage(url: model.iconURL,
                         placeholderImage: Theme.icon.checkmark) { image in
                image
                    .resizable()
                    .renderingMode(.template)
            } placeholder: {
                ProgressView()
            }
            .foregroundColor(Theme.color.iconAccent)
            .frame(width: Constants.iconSize, height: Constants.iconSize)

            Text(model.title)
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .foregroundColor(textColor)
            
            Text(model.free)
                .font(.system(size: 14))
                .frame(width: Constants.valueColumnWidth, alignment: .center)
                .lineLimit(1)
                .foregroundColor(textColor)
            
            Text(model.plus)
                .font(.system(size: 14))
                .frame(width: Constants.valueColumnWidth, alignment: .center)
                .lineLimit(1)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    let model = FeatureRowModel(icon: "bubble.left",
                                text: "Daily chats::Limited::Unlimited")

    FeatureRow(model: model)
}


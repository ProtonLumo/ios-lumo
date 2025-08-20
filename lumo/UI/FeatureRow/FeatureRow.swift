import SwiftUI
import ProtonUIFoundations

struct FeatureRow: View {
    let model: FeatureRowModel
    
    private struct Constants {
        static var iconSize: CGFloat = 15
        static var valueColumnWidth: CGFloat = 75
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
                .foregroundColor(.black)
            
            Text(model.free)
                .font(.system(size: 14))
                .frame(width: Constants.valueColumnWidth, alignment: .center)
                .lineLimit(1)
                .foregroundColor(.black)
            
            Text(model.plus)
                .font(.system(size: 14))
                .frame(width: Constants.valueColumnWidth, alignment: .center)
                .lineLimit(1)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    let model = FeatureRowModel(icon: "bubble.left",
                                text: "Daily chats::Limited::Unlimited")

    FeatureRow(model: model)
}


import SwiftUI

struct FallbackAsyncImage: View {
    let url: URL?
    let fallbackImage: UIImage?

    var body: some View {
        AsyncImage(
            url: url,
            content: { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .renderingMode(.template)
                case .failure:
                    if let fallbackImage {
                        Image(uiImage: fallbackImage)
                            .resizable()
                            .renderingMode(.template)
                    } else {
                        EmptyView()
                    }
                @unknown default:
                    EmptyView()
                }
            }
        )
    }
}

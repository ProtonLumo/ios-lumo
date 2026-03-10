import LumoDesignSystem
import SwiftUI

struct ComposerAttachmentsView: View {
    let files: [File]
    /// Used for text and icon colors
    let accentColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let onAttachmentTapped: (_ id: String) -> Void
    let onRemoveTapped: (_ id: String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center, spacing: DS.Spacing.standard) {
                ForEach(files, id: \.id) { file in
                    AttachmentButton(
                        file: file,
                        accentColor: accentColor,
                        backgroundColor: backgroundColor,
                        borderColor: borderColor,
                        onAttachmentTapped: onAttachmentTapped,
                        onRemoveTapped: onRemoveTapped
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        .fixedSize(horizontal: false, vertical: true)
        .scrollIndicators(.hidden)
    }
}

#if DEBUG
    let portraitImage: String =
        "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"

    let landscapeImage: String =
        "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"

    #Preview {
        ComposerAttachmentsView(
            files: [
                .init(id: "1", name: "Report.pdf", type: .pdf, preview: portraitImage),
                .init(id: "2", name: "Data.xls", type: .xls, preview: .none),
                .init(id: "3", name: "Slides.ppt", type: .ppt, preview: .none),
                .init(id: "4", name: "Image.jpg", type: .image, preview: landscapeImage),
                .init(id: "5", name: "Video.mp4", type: .video, preview: .none),
            ],
            accentColor: DS.Color.Text.weak,
            backgroundColor: DS.Color.Background.weak,
            borderColor: DS.Color.Border.weak,
            onAttachmentTapped: { _ in },
            onRemoveTapped: { _ in }
        )
    }
#endif

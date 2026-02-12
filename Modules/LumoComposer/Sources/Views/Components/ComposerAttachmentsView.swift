import LumoDesignSystem
import SwiftUI

struct ComposerAttachmentsView: View {
    let files: [File]
    /// Used for text and icon colors
    let accentColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let onAttachmentTapped: (_ id: String) -> Void
    let onTrashTapped: (_ id: String) -> Void

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
                        onTrashTapped: onTrashTapped
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
    #Preview {
        ComposerAttachmentsView(
            files: [
                .init(id: "1", name: "Report.pdf", type: .pdf),
                .init(id: "2", name: "Data.xls", type: .xls),
                .init(id: "3", name: "Slides.ppt", type: .ppt),
                .init(id: "4", name: "Image.jpg", type: .image),
                .init(id: "5", name: "Video.mp4", type: .video),
            ],
            accentColor: DS.Color.Text.weak,
            backgroundColor: DS.Color.Background.weak,
            borderColor: DS.Color.Border.weak,
            onAttachmentTapped: { _ in },
            onTrashTapped: { _ in }
        )
    }
#endif

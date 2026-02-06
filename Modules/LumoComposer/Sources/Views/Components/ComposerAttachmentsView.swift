import LumoDesignSystem
import SwiftUI

struct ComposerAttachmentsView: View {
    let files: [File]
    let isGhostModeEnabled: Bool
    let onTrashTapped: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center, spacing: DS.Spacing.standard) {
                ForEach(files, id: \.name) { file in
                    HStack(spacing: DS.Spacing.mediumLight) {
                        file.type
                            .image
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: .zero) {
                            Text(file.name)
                                .font(.caption.weight(.semibold))
                            Text(file.type.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(isGhostModeEnabled ? DS.Color.Text.weakDark : DS.Color.Text.weak)
                        .frame(maxWidth: 95)
                        Button(
                            action: onTrashTapped,
                            label: {
                                DS.Icon.icTrash.swiftUIImage
                                    .foregroundStyle(isGhostModeEnabled ? DS.Color.Text.weakDark : DS.Color.Text.weak)
                            }
                        )
                    }
                    .padding(.all, DS.Spacing.medium)
                    .background {
                        RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                            .fill(isGhostModeEnabled ? DS.Color.Background.weakDarkOnly : DS.Color.Background.weak)
                            .strokeBorder(isGhostModeEnabled ? DS.Color.Border.weakDark : DS.Color.Border.weak, lineWidth: 1)
                    }
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
                .init(name: "Report.pdf", type: .pdf),
                .init(name: "Data.xls", type: .xls),
                .init(name: "Slides.ppt", type: .ppt),
                .init(name: "Image.jpg", type: .image),
                .init(name: "Video.mp4", type: .video),
            ],
            isGhostModeEnabled: false,
            onTrashTapped: {}
        )
    }
#endif

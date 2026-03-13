import LumoDesignSystem
import LumoUI
import SwiftUI

struct AttachmentButton: View {
    let file: File
    /// Used for text and icon colors
    let accentColor: Color
    let backgroundColor: Color
    let borderColor: Color
    let onAttachmentTapped: (_ id: String) -> Void
    let onRemoveTapped: (_ id: String) -> Void

    var body: some View {
        Button(
            action: { onAttachmentTapped(file.id) },
            label: {
                ZStack(alignment: .center) {
                    image
                        .padding(.horizontal, DS.Spacing.compact)
                        .padding(.vertical, DS.Spacing.large)

                    VStack(spacing: .zero) {
                        HStack(spacing: .zero) {
                            Spacer()
                            removeButton(action: { onRemoveTapped(file.id) })
                        }

                        Spacer()

                        filenameView
                    }
                    .padding(DS.Spacing.compact)
                }
            }
        )
        .frame(minWidth: 100, maxWidth: 130)
        .frame(height: 127)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                .fill(backgroundColor)
        }
    }

    @ViewBuilder
    private var image: some View {
        if let preview = file.preview,
            let data = Data(base64Encoded: preview),
            let uiImage = UIImage(data: data)
        {
            let isLandscape = uiImage.size.width > uiImage.size.height

            Image(uiImage: uiImage)
                .resizable()
                .frame(
                    width: isLandscape ? 118 : 73,
                    height: isLandscape ? 63 : 96
                )
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        } else {
            file.type
                .image
                .resizable()
                .square(size: 36)
        }
    }

    @ViewBuilder
    private func removeButton(action: @escaping () -> Void) -> some View {
        Button(
            action: action,
            label: {
                DS.Icon.icCross.swiftUIImage
                    .foregroundStyle(accentColor)
                    .padding(DS.Spacing.tiny)
                    .background {
                        RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                            .fill(backgroundColor)
                            .strokeBorder(borderColor, lineWidth: 1)
                    }
            }
        )
    }

    @ViewBuilder
    private var filenameView: some View {
        Text(file.name)
            .lineLimit(2)
            .font(.caption)
            .foregroundStyle(accentColor)
            .padding(.vertical, DS.Spacing.tiny)
            .padding(.horizontal, DS.Spacing.mediumLight)
            .background {
                RoundedRectangle(cornerRadius: DS.Radius.huge)
                    .fill(backgroundColor)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
    }
}

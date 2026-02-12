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
    let onTrashTapped: (_ id: String) -> Void

    var body: some View {
        Button(
            action: { onAttachmentTapped(file.id) },
            label: {
                HStack(spacing: DS.Spacing.mediumLight) {
                    file.type
                        .image
                        .square(size: 24)
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(file.name)
                            .font(.caption.weight(.semibold))
                        Text(file.type.rawValue)
                            .font(.caption)
                    }
                    .foregroundStyle(accentColor)
                    .frame(maxWidth: 95)
                    Button(
                        action: { onTrashTapped(file.id) },
                        label: {
                            DS.Icon.icTrash.swiftUIImage
                                .foregroundStyle(accentColor)
                                .square(size: 24)
                        }
                    )
                }
            }
        )
        .padding(.all, DS.Spacing.medium)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                .fill(backgroundColor)
                .strokeBorder(borderColor, lineWidth: 1)
        }
    }
}

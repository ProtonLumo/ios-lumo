import LumoDesignSystem
import SwiftUI

struct AddAttachmentButton: View {
    let title: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.standard) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(DS.Color.Text.norm)
                icon
                    .square(size: 24)
                    .foregroundStyle(DS.Color.Text.norm)
            }
        }
    }
}

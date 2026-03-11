import LumoDesignSystem
import SwiftUI

struct ImageModeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.mediumLight) {
                DS.Icon.icPalette.swiftUIImage
                    .foregroundStyle(DS.Color.primary)
                DS.Icon.icCross.swiftUIImage
                    .foregroundStyle(DS.Color.primary)
            }
            .padding(.all, DS.Spacing.compact)
            .background {
                RoundedRectangle(cornerRadius: DS.Radius.massive)
                    .fill(DS.Color.primary.opacity(0.1))
            }
        }
    }
}

import LumoDesignSystem
import SwiftUI

struct SelectModelButton: View {
    let model: WebComposerState.Model
    let color: Color
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.standard) {
                Text(model.rawValue.capitalized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isDisabled ? color.opacity(0.6) : color)
                DS.Icon.icChevronTinyDown.swiftUIImage
                    .foregroundStyle(isDisabled ? color.opacity(0.6) : color)
            }
            .padding(.horizontal, DS.Spacing.mediumLight)
            .padding(.vertical, DS.Spacing.compact)
        }
    }
}

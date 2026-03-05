import LumoDesignSystem
import LumoUI
import SwiftUI

struct ComposerToggleButton: View {
    let icon: Image
    let iconColor: Color
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon
                .font(.system(size: 20))
                .foregroundStyle(isDisabled ? iconColor.opacity(0.6) : iconColor)
                .square(size: 36)
        }
        .buttonStyle(ComposerToggleButtonStyle())
    }
}

private struct ComposerToggleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? DS.Color.Interaction.defaultHover : .clear)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
    }
}

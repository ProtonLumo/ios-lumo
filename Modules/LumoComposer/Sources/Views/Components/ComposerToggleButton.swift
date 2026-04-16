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
                .foregroundStyle(iconColor)
                .square(size: 36)
        }
        .buttonStyle(ComposerToggleButtonStyle())
        .disabled(isDisabled)
    }
}

private struct ComposerToggleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? 1 : 0.5)
            .background(configuration.isPressed ? DS.Color.Interaction.defaultHover : .clear)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
    }
}

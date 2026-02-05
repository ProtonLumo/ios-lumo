import LumoDesignSystem
import SwiftUI

struct ComposerToggleButton: View {
    let icon: ImageResource
    let isOn: Bool
    let isGhostModeEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(icon)
                .font(.system(size: 20))
                .foregroundStyle(isGhostModeEnabled ? DS.Color.Text.weakDark : DS.Color.Text.weak)
                .frame(width: 36, height: 36)
                .background {
                    RoundedRectangle(cornerRadius: DS.Radius.medium)
                        .fill(isOn ? DS.Color.Interaction.defaultHover : Color.clear)
                }
        }
        .buttonStyle(.plain)
    }
}

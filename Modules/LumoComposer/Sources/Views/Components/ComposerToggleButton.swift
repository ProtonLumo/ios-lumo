import LumoDesignSystem
import SwiftUI

struct ComposerToggleButton: View {
    let icon: Image
    let iconColor: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            icon
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background {
                    RoundedRectangle(cornerRadius: DS.Radius.medium)
                        .fill(isOn ? DS.Color.Interaction.defaultHover : Color.clear)
                }
        }
        .buttonStyle(.plain)
    }
}

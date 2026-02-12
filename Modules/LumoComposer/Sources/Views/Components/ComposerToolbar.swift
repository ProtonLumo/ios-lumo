import LumoDesignSystem
import SwiftUI

struct ComposerToolbar: View {
    let iconColor: Color
    let isWebSearchEnabled: Bool
    let onPaperclipTap: () -> Void
    let onGlobeTap: () -> Void
    let onMicrophoneTap: () -> Void

    var body: some View {
        HStack(spacing: .zero) {
            HStack(spacing: DS.Spacing.compact) {
                ComposerToggleButton(
                    icon: DS.Icon.icPaperClip.swiftUIImage,
                    iconColor: iconColor,
                    isOn: false,
                    action: onPaperclipTap
                )

                ComposerToggleButton(
                    icon: DS.Icon.icGlobe.swiftUIImage,
                    iconColor: iconColor,
                    isOn: isWebSearchEnabled,
                    action: onGlobeTap
                )
            }
            Spacer()
            ComposerToggleButton(
                icon: DS.Icon.icMicrophone.swiftUIImage,
                iconColor: iconColor,
                isOn: false,
                action: onMicrophoneTap
            )
        }
    }
}

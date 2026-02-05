import LumoDesignSystem
import SwiftUI

struct ComposerToolbar: View {
    let isGhostModeEnabled: Bool
    let isWebSearchEnabled: Bool
    let onPaperclipTap: () -> Void
    let onGlobeTap: () -> Void
    let onMicrophoneTap: () -> Void

    var body: some View {
        HStack(spacing: .zero) {
            HStack(spacing: DS.Spacing.compact) {
                ComposerToggleButton(
                    icon: DS.Icon.paperClip,
                    isOn: false,
                    isGhostModeEnabled: isGhostModeEnabled,
                    action: onPaperclipTap
                )

                ComposerToggleButton(
                    icon: DS.Icon.globe,
                    isOn: isWebSearchEnabled,
                    isGhostModeEnabled: isGhostModeEnabled,
                    action: onGlobeTap
                )
            }
            Spacer()
            ComposerToggleButton(
                icon: DS.Icon.microphone,
                isOn: false,
                isGhostModeEnabled: isGhostModeEnabled,
                action: onMicrophoneTap
            )
        }
    }
}

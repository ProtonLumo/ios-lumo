import LumoDesignSystem
import SwiftUI

struct ComposerActionButton: View {
    let action: () -> Void
    let icon: ImageResource
    let isGhostModeEnabled: Bool

    var body: some View {
        Button(
            action: action,
            label: {
                Image(icon)
                    .foregroundStyle(isGhostModeEnabled ? DS.Color.Background.normDarkOnly : DS.Color.Background.norm)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(DS.Color.primary)
                    }
            }
        )
    }
}

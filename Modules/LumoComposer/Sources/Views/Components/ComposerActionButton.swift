import LumoDesignSystem
import LumoUI
import SwiftUI

struct ComposerActionButton: View {
    let action: () -> Void
    let icon: Image
    let iconColor: Color

    var body: some View {
        Button(
            action: action,
            label: {
                icon
                    .foregroundStyle(iconColor)
                    .square(size: 36)
                    .background {
                        Circle()
                            .fill(DS.Color.primary)
                    }
            }
        )
    }
}

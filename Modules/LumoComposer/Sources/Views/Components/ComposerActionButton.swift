import LumoDesignSystem
import LumoUI
import SwiftUI

struct ComposerActionButton: View {
    static let size: CGFloat = 36

    let action: () -> Void
    let icon: Image
    let iconColor: Color

    var body: some View {
        Button(
            action: action,
            label: {
                icon
                    .foregroundStyle(iconColor)
                    .square(size: Self.size)
                    .background {
                        Circle()
                            .fill(DS.Color.primary)
                    }
            }
        )
    }
}

import LumoDesignSystem
import LumoUI
import SwiftUI

struct ComposerActionButton: View {
    static let size: CGFloat = 36

    let state: ComposerView.ActionButtonState
    let iconColor: Color
    let action: (ComposerView.Action) -> Void

    var body: some View {
        Button(
            action: { action(state.composerAction) },
            label: {
                Image(systemName: state.symbolName)
                    .contentTransition(.symbolEffect(.replace))
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

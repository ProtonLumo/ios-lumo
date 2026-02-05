import LumoDesignSystem
import SwiftUI

struct ComposerInput: View {
    @Binding var text: String
    let isGhostModeEnabled: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(L10n.Composer.placeholder)
                    .font(.body)
                    .foregroundStyle(isGhostModeEnabled ? DS.Color.Text.hintDark : DS.Color.Text.hint)
                    .allowsHitTesting(false)
            }

            TextField(String(""), text: $text, axis: .vertical)
                .foregroundStyle(isGhostModeEnabled ? DS.Color.Text.normDarkOnly : DS.Color.Text.norm)
                .focused($isFocused)
                .lineLimit(1...10)
                .tint(DS.Color.primary)
        }
    }
}

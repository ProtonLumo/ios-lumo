import LumoDesignSystem
import SwiftUI

struct ComposerInput: View {
    @Binding var text: String
    let placeholderColor: Color
    let textColor: Color
    let backgroundColor: Color
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(L10n.Composer.placeholder)
                    .font(.body)
                    .foregroundStyle(placeholderColor)
                    .allowsHitTesting(false)
            }

            TextField(String(""), text: $text, axis: .vertical)
                .foregroundStyle(textColor)
                .focused($isFocused)
                .lineLimit(1...10)
                .tint(DS.Color.primary)
        }
        .background(backgroundColor)
        .padding(.vertical, DS.Spacing.large)
    }
}

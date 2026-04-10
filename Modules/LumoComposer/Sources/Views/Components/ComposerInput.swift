import LumoDesignSystem
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct ComposerInput: View {
    @Binding var text: String
    let placeholderText: LocalizedStringResource
    let placeholderColor: Color
    let textColor: Color
    let backgroundColor: Color
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholderText)
                    .font(.body)
                    .foregroundStyle(placeholderColor)
                    .allowsHitTesting(false)
            }

            TextField(String(""), text: $text, axis: .vertical)
                .foregroundStyle(textColor)
                .tint(DS.Color.primary)
                .focused($isFocused)
                .lineLimit(1...10)
                .introspect(.textEditor, on: .iOS(.v17...)) { textEditor in
                    textEditor.autocorrectionType = .no
                    textEditor.spellCheckingType = .no
                }
        }
        .background(backgroundColor)
        .padding(.vertical, DS.Spacing.large)
    }
}

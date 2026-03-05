import LumoDesignSystem
import SwiftUI

struct ToolItem<Content: View>: View {
    let icon: Image
    let text: LocalizedStringResource
    let trailingElement: (() -> Content)?

    var body: some View {
        HStack(spacing: DS.Spacing.medium) {
            icon
                .square(size: 20)
                .foregroundStyle(DS.Color.Text.norm)
                .padding(.all, DS.Spacing.standard)
            Text(text)
                .font(.headline.weight(.medium))
                .foregroundStyle(DS.Color.Text.norm)
            Spacer()
            if let element = trailingElement?() {
                element
            }
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.moderatelyLarge)
    }
}

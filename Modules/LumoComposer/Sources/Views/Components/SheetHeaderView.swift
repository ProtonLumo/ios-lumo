import LumoDesignSystem
import SwiftUI

struct SheetHeaderView: View {
    let title: LocalizedStringResource
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 18))
                .foregroundStyle(DS.Color.Text.norm)
                .padding(.leading, DS.Spacing.compact)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(DS.Color.Text.norm)
                    .square(size: 30)
                    .padding(DS.Spacing.tiny)
                    .background {
                        Circle()
                            .fill(.secondary)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding([.top, .horizontal], DS.Spacing.large)
    }
}

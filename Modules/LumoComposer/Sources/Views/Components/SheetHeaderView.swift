import LumoDesignSystem
import ProtonUIFoundations
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
            CloseButton(size: 34, action: onClose)
        }
        .padding([.top, .horizontal], DS.Spacing.large)
    }
}

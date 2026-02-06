import LumoDesignSystem
import SwiftUI

struct ComposerAttachmentsView: View {
    let files: [File]
    let isGhostModeEnabled: Bool

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center, spacing: DS.Spacing.standard) {
                ForEach(files, id: \.name) { file in
                    HStack(spacing: DS.Spacing.mediumLight) {
                        file.type
                            .image
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: .zero) {
                            Text(file.name)
                                .font(.caption.weight(.semibold))
                            Text(file.type.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(isGhostModeEnabled ? DS.Color.Text.weakDark : DS.Color.Text.weak)
                        .frame(maxWidth: 95)
                    }
                    .padding([.leading, .top, .bottom], DS.Spacing.medium)
                    .padding([.trailing], DS.Spacing.jumbo)
                    .background {
                        RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                            .fill(isGhostModeEnabled ? DS.Color.Background.weakDarkOnly : DS.Color.Background.weak)
                            .strokeBorder(isGhostModeEnabled ? DS.Color.Border.weakDark : DS.Color.Border.weak, lineWidth: 1)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        .fixedSize(horizontal: false, vertical: true)
        .scrollIndicators(.hidden)
    }
}

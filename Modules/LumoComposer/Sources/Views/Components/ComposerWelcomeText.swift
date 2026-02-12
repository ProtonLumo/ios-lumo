import LumoDesignSystem
import SwiftUI

struct ComposerWelcomeText: View {
    var body: some View {
        VStack(spacing: -DS.Spacing.standard) {
            ForEach(lines, id: \.self) { line in
                Text(line)
            }
        }
        .font(.syneMedium(size: 32))
        .kerning(-0.8)
        .foregroundStyle(DS.Color.Text.norm)
        .multilineTextAlignment(.center)
    }

    // MARK: - Private

    private let lines: [String] = [
        String(localized: L10n.Welcome.greeting),
        String(localized: L10n.Welcome.prompt),
        String(localized: L10n.Welcome.confidentiality),
    ]
}

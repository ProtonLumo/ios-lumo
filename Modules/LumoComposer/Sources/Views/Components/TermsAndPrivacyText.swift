import LumoDesignSystem
import SwiftUI

struct TermsAndPrivacyText: View {
    var body: some View {
        Text(attributedText)
            .font(.interRegular(size: 12))
            .foregroundStyle(DS.Color.Text.weak)
            .tint(DS.Color.Text.weak)
    }

    // MARK: - Private

    private let termsURL = "https://lumo.proton.me/legal/terms"
    private let privacyURL = "https://lumo.proton.me/legal/privacy"

    private var attributedText: AttributedString {
        var text = attributedString

        for run in text.runs where run.link != nil {
            text[run.range].underlineStyle = .single
        }

        return text
    }

    private var attributedString: AttributedString {
        let localized = L10n.Composer.termsAndPrivacy(termsURL: termsURL, privacyURL: privacyURL)
        let attributedMarkdown = try? AttributedString(markdown: String(localized: localized))

        return attributedMarkdown ?? AttributedString(localized: localized)
    }
}

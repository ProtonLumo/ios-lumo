import Foundation

/// Once you define `LocalizedStringResource` below Xcode puts related string in `Localizable.xcstrings` file.
/// The generation happens automatically when adding/removing string below. All keys are added in alphabetical order.
/// IMPORTANT: Remember about setting bundle for each key: `bundle: .module`.
enum L10n {
    enum Composer {
        static let placeholder = LocalizedStringResource(
            "Ask anything...",
            bundle: .module,
            comment: "Placeholder text shown in the composer input field when empty for non-image mode"
        )
        static let placeholderImage = LocalizedStringResource(
            "Describe your image",
            bundle: .module,
            comment: "Placeholder text shown in the composer input field when empty for image mode"
        )
        static func termsAndPrivacy(
            termsURL: String,
            privacyURL: String
        ) -> LocalizedStringResource {
            .init(
                "By using Lumo, you agree to our [Terms](\(termsURL)) and [Privacy Policy](\(privacyURL)).",
                bundle: .module,
                comment: "Terms and privacy policy agreement text with clickable links. The text uses Markdown format with embedded URLs that should not be translated."
            )
        }
    }

    enum Attachment {
        static let protonDrive = LocalizedStringResource(
            "Proton Drive",
            bundle: .module,
            comment: "Attachment menu option to attach a file from Proton Drive"
        )
        static let files = LocalizedStringResource(
            "Files",
            bundle: .module,
            comment: "Attachment menu option to attach a file from the device's file system"
        )
        static let camera = LocalizedStringResource(
            "Camera",
            bundle: .module,
            comment: "Attachment menu option to take a photo using the camera"
        )
        static let photos = LocalizedStringResource(
            "Photos",
            bundle: .module,
            comment: "Attachment menu option to select a photo from the photo library"
        )
        static let sketch = LocalizedStringResource(
            "Draw a sketch",
            bundle: .module,
            comment: "Attachment menu option to draw a sketch and attach it to the message"
        )
    }

    enum Welcome {
        static let greeting = LocalizedStringResource(
            "Hey, I'm Lumo.",
            bundle: .module,
            comment: "First line of welcome message - Lumo's introduction"
        )
        static let prompt = LocalizedStringResource(
            "Ask me anything.",
            bundle: .module,
            comment: "Second line of welcome message - invitation to ask questions"
        )
        static let confidentiality = LocalizedStringResource(
            "It's confidential.",
            bundle: .module,
            comment: "Third line of welcome message - privacy assurance"
        )
    }
}

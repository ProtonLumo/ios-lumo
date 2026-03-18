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

    enum Error {
        static let generic = LocalizedStringResource(
            "Something went wrong. Please try again.",
            bundle: .module,
            comment: "Generic error message shown in a toast when communication between the iOS app and the Web API fails (e.g. sending a prompt, toggling web search, changing the model)"
        )
        static let duplicateFile = LocalizedStringResource(
            "This file is already attached.",
            bundle: .module,
            comment: "Error shown when the user tries to attach a file that has already been attached to the message"
        )
        static let generationError = LocalizedStringResource(
            "Failed to generate a response. Please try again.",
            bundle: .module,
            comment: "Error shown when the AI response generation fails"
        )
        static let generationRejected = LocalizedStringResource(
            "Your request could not be processed. Please try again.",
            bundle: .module,
            comment: "Error shown when the AI response generation is rejected"
        )
        static let harmfulContent = LocalizedStringResource(
            "Your request contains content that cannot be processed.",
            bundle: .module,
            comment: "Error shown when the user's message is detected as harmful or violating content policy"
        )
        static let highDemand = LocalizedStringResource(
            "Lumo is experiencing high demand. Please try again later.",
            bundle: .module,
            comment: "Error shown when the AI service is overloaded due to high demand"
        )
        static let streamDisconnected = LocalizedStringResource(
            "Connection lost. Please try again.",
            bundle: .module,
            comment: "Error shown when the streaming connection to the AI service is interrupted"
        )
        static let tierLimit = LocalizedStringResource(
            "You've reached your usage limit.",
            bundle: .module,
            comment: "Error shown when the user has exceeded their plan's usage quota"
        )
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

    enum ModelSelectionSheet {
        static let title = LocalizedStringResource(
            "Models",
            bundle: .module,
            comment: "Title of the model selection bottom sheet"
        )
        static let autoTitle = LocalizedStringResource(
            "Auto",
            bundle: .module,
            comment: "Name of the Auto model in the model selection sheet"
        )
        static let autoSubtitle = LocalizedStringResource(
            "Auto choose the best model",
            bundle: .module,
            comment: "Subtitle describing the Auto model in the model selection sheet"
        )
        static let fastTitle = LocalizedStringResource(
            "Fast",
            bundle: .module,
            comment: "Name of the Fast model in the model selection sheet"
        )
        static let fastSubtitle = LocalizedStringResource(
            "Quick responses",
            bundle: .module,
            comment: "Subtitle describing the Fast model in the model selection sheet"
        )
        static let thinkingTitle = LocalizedStringResource(
            "Thinking",
            bundle: .module,
            comment: "Name of the Thinking model in the model selection sheet. Note: 'lumo+' badge is shown separately in the UI and should not be included here."
        )
        static let thinkingSubtitle = LocalizedStringResource(
            "Solves complex problems",
            bundle: .module,
            comment: "Subtitle describing the Thinking model in the model selection sheet"
        )
    }

    enum ToolsSheet {
        static let title = LocalizedStringResource(
            "Tools",
            bundle: .module,
            comment: "Title of the tools bottom sheet"
        )
        static let createImage = LocalizedStringResource(
            "Create image",
            bundle: .module,
            comment: "Option in tools sheet to enable image creation mode"
        )
        static let webSearch = LocalizedStringResource(
            "Web search",
            bundle: .module,
            comment: "Option in tools sheet to toggle web search"
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

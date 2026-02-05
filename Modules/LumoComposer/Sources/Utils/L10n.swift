import Foundation

/// Once you define `LocalizedStringResource` below Xcode puts related string in `Localizable.xcstrings` file.
/// The generation happens automatically when adding/removing string below. All keys are added in alphabetical order.
/// IMPORTANT: Remember about setting bundle for each key: `bundle: .module`.
enum L10n {
    static let inputPlaceholder = LocalizedStringResource(
        "Ask anything...",
        bundle: .module,
        comment: "Placeholder text for the composer input."
    )
}

import Foundation

/// State received from WebView
///
/// This represents the complete state of the composer as synchronized from the web application.
/// All properties are immutable - state updates come as complete new instances.
struct WebComposerState: Equatable, Decodable {
    /// Represents working state
    ///
    /// This enum has only two states to keep the state machine simple:
    /// - `idle`: Lumo is ready to accept new input
    /// - `working`: Lumo is actively processing (thinking or responding)
    enum Mode: String, Equatable, Decodable {
        case idle = "Idle"
        case working = "Working"
    }

    let mode: Mode
    let isGhostModeEnabled: Bool
    let isWebSearchEnabled: Bool
    let isVisible: Bool
    let showTermsAndPrivacy: Bool
    let attachedFiles: [File]

    enum CodingKeys: String, CodingKey {
        case mode = "lumoMode"
        case isGhostModeEnabled
        case isWebSearchEnabled
        case isVisible
        case showTermsAndPrivacy = "showTsAndCs"
        case attachedFiles
    }
}

extension WebComposerState {
    static var initial: Self {
        .init(
            mode: .idle,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isVisible: true,
            showTermsAndPrivacy: true,
            attachedFiles: []
        )
    }
}

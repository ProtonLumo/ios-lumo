import Foundation

/// State received from WebView
///
/// This represents the complete state of the composer as synchronized from the web application.
/// All properties are immutable - state updates come as complete new instances.
public struct WebComposerState: Equatable, Decodable {
    /// Represents working state
    ///
    /// This enum has only two states to keep the state machine simple:
    /// - `idle`: Lumo is ready to accept new input
    /// - `working`: Lumo is actively processing (thinking or responding)
    enum Mode: String, Equatable, Decodable {
        case idle = "Idle"
        case working = "Working"
    }

    public enum ModelType: String, Equatable, Decodable {
        case auto = "Auto"
        case fast = "Fast"
        case thinking = "Thinking"
    }

    let mode: Mode
    let modelType: ModelType
    let isGhostModeEnabled: Bool
    let isWebSearchEnabled: Bool
    let isCreateImageEnabled: Bool
    let isVisible: Bool
    let showTermsAndPrivacy: Bool
    let attachedFiles: [File]

    enum CodingKeys: String, CodingKey {
        case mode = "lumoMode"
        case modelType
        case isGhostModeEnabled
        case isWebSearchEnabled
        case isCreateImageEnabled
        case isVisible
        case showTermsAndPrivacy = "showTsAndCs"
        case attachedFiles
    }
}

extension WebComposerState {
    static var initial: Self {
        .init(
            mode: .idle,
            modelType: .auto,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isCreateImageEnabled: false,
            isVisible: true,
            showTermsAndPrivacy: true,
            attachedFiles: []
        )
    }
}

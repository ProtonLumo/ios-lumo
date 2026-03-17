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
    enum Mode: String, Decodable, Equatable {
        case idle = "Idle"
        case working = "Working"
    }

    public enum ModelTier: String, CaseIterable, Decodable, Equatable, Sendable {
        case auto = "auto"
        case fast = "fast"
        case thinking = "thinking"
    }

    struct FeatureFlags: Equatable, Decodable {
        let isImageGenEnabled: Bool
        let isModelSelectionEnabled: Bool

        enum CodingKeys: String, CodingKey {
            case isImageGenEnabled
            case isModelSelectionEnabled
        }
    }

    let mode: Mode
    let model: ModelTier
    let isGhostModeEnabled: Bool
    let isWebSearchEnabled: Bool
    let isCreateImageEnabled: Bool
    let isVisible: Bool
    let showTermsAndPrivacy: Bool
    let attachedFiles: [File]
    let featureFlags: FeatureFlags
    let isFreeUser: Bool

    enum CodingKeys: String, CodingKey {
        case mode = "lumoMode"
        case model = "modelTier"
        case isGhostModeEnabled
        case isWebSearchEnabled
        case isCreateImageEnabled
        case isVisible
        case showTermsAndPrivacy = "showTsAndCs"
        case attachedFiles
        case featureFlags
        case isFreeUser
    }

    func copy(attachedFiles: [File]) -> Self {
        .init(
            mode: mode,
            model: model,
            isGhostModeEnabled: isGhostModeEnabled,
            isWebSearchEnabled: isWebSearchEnabled,
            isCreateImageEnabled: isCreateImageEnabled,
            isVisible: isVisible,
            showTermsAndPrivacy: showTermsAndPrivacy,
            attachedFiles: attachedFiles,
            featureFlags: featureFlags,
            isFreeUser: isFreeUser
        )
    }
}

extension WebComposerState {
    static var initial: Self {
        .init(
            mode: .idle,
            model: .auto,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isCreateImageEnabled: false,
            isVisible: true,
            showTermsAndPrivacy: true,
            attachedFiles: [],
            featureFlags: .initial,
            isFreeUser: true
        )
    }
}

extension WebComposerState.FeatureFlags {
    static var initial: Self {
        .init(isImageGenEnabled: false, isModelSelectionEnabled: false)
    }
}

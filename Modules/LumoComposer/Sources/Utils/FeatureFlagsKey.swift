import SwiftUI

struct FeatureFlagsKey: EnvironmentKey {
    static let defaultValue: WebComposerState.FeatureFlags = .init(isImageGenEnabled: false, isModelSelectionEnabled: false)
}

extension EnvironmentValues {
    var featureFlags: WebComposerState.FeatureFlags {
        get { self[FeatureFlagsKey.self] }
        set { self[FeatureFlagsKey.self] = newValue }
    }
}

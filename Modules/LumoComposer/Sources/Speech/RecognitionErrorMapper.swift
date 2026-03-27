import Foundation

enum RecognitionErrorMapper {
    enum Action {
        case ignore
        case permissionDenied
    }

    /// Maps a known recognition error into an action.
    /// Returns `nil` for unrecognized errors — caller decides how to handle.
    static func action(for error: Error) -> Action? {
        let nsError = error as NSError

        switch nsError.domain {
        case "kLSRErrorDomain":
            guard let code = LSRError(rawValue: nsError.code) else { return nil }
            switch code {
            case .cancelled: return .ignore
            case .siriDisabled: return .permissionDenied
            case .assetsNotInstalled, .initializationFailed: return nil
            }

        case "kAFAssistantErrorDomain":
            guard let code = AFAssistantError(rawValue: nsError.code) else { return nil }
            switch code {
            case .connectionInterrupted, .noSpeechDetected: return .ignore
            case .notAuthorized: return .permissionDenied
            case .recognitionFailure, .alreadyActive, .connectionInvalidated: return nil
            }

        default:
            return nil
        }
    }
}

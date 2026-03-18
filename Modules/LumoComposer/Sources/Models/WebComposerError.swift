import Foundation

public enum WebComposerError: String, Decodable, LocalizedError {
    case unknown = "Unknown"
    case streamDisconnected = "StreamDisconnected"
    case generationError = "GenerationError"
    case highDemand = "HighDemand"
    case generationRejected = "GenerationRejected"
    case harmfulContent = "HarmfulContent"
    case tierLimit = "TierLimit"
    case duplicateFile = "DuplicateFile"

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .unknown:
            String(localized: L10n.Error.generic)
        case .streamDisconnected:
            String(localized: L10n.Error.streamDisconnected)
        case .generationError:
            String(localized: L10n.Error.generationError)
        case .highDemand:
            String(localized: L10n.Error.highDemand)
        case .generationRejected:
            String(localized: L10n.Error.generationRejected)
        case .harmfulContent:
            String(localized: L10n.Error.harmfulContent)
        case .tierLimit:
            String(localized: L10n.Error.tierLimit)
        case .duplicateFile:
            String(localized: L10n.Error.duplicateFile)
        }
    }
}

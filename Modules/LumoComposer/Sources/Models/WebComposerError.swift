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
            L10n.Error.generic.string
        case .streamDisconnected:
            L10n.Error.streamDisconnected.string
        case .generationError:
            L10n.Error.generationError.string
        case .highDemand:
            L10n.Error.highDemand.string
        case .generationRejected:
            L10n.Error.generationRejected.string
        case .harmfulContent:
            L10n.Error.harmfulContent.string
        case .tierLimit:
            L10n.Error.tierLimit.string
        case .duplicateFile:
            L10n.Error.duplicateFile.string
        }
    }
}

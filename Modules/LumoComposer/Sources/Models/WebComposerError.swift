import Foundation

public enum WebComposerError: String, Decodable, LocalizedError {
    // Generation errors
    case generationError = "GenerationError"
    case generationRejected = "GenerationRejected"
    case harmfulContent = "HarmfulContent"
    case highDemand = "HighDemand"
    case streamDisconnected = "StreamDisconnected"

    // Upload errors
    case duplicateFile = "DuplicateFile"

    // Tier / limit errors
    case tierLimit = "TierLimit"
    case messageLimitReached = "MessageLimitReached"
    case assetLimitReached = "AssetLimitReached"
    case conversationLimitReached = "ConversationLimitReached"
    case spaceLimitReached = "SpaceLimitReached"

    // Fallback
    case unknown = "Unknown"

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .generationError:
            L10n.Error.generationError.string
        case .generationRejected:
            L10n.Error.generationRejected.string
        case .harmfulContent:
            L10n.Error.harmfulContent.string
        case .highDemand:
            L10n.Error.highDemand.string
        case .streamDisconnected:
            L10n.Error.streamDisconnected.string
        case .duplicateFile:
            L10n.Error.duplicateFile.string
        case .tierLimit:
            L10n.Error.tierLimit.string
        case .messageLimitReached:
            L10n.Error.messageLimitReached.string
        case .assetLimitReached:
            L10n.Error.assetLimitReached.string
        case .conversationLimitReached:
            L10n.Error.conversationLimitReached.string
        case .spaceLimitReached:
            L10n.Error.spaceLimitReached.string
        case .unknown:
            L10n.Error.generic.string
        }
    }
}

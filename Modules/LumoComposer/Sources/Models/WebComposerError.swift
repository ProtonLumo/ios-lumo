public enum WebComposerError: String, Decodable {
    case unknown = "Unknown"
    case streamDisconnected = "StreamDisconnected"
    case generationError = "GenerationError"
    case highDemand = "HighDemand"
    case generationRejected = "GenerationRejected"
    case harmfulContent = "HarmfulContent"
    case tierLimit = "TierLimit"
    case duplicateFile = "DuplicateFile"
}

/// Error codes from `kAFAssistantErrorDomain` (Apple Assistant framework, private).
/// Reference: https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/error
enum AFAssistantError: Int {
    /// Failure occurred during speech recognition.
    case recognitionFailure = 203
    /// Trying to start recognition while an earlier instance is still active.
    case alreadyActive = 1100
    /// Connection to speech process was invalidated.
    case connectionInvalidated = 1101
    /// Connection to speech process was interrupted.
    case connectionInterrupted = 1107
    /// Failed to recognize any speech.
    case noSpeechDetected = 1110
    /// Request is not authorized.
    case notAuthorized = 1700
}

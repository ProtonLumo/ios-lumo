/// Error codes from `kLSRErrorDomain` (Apple Speech framework, private).
/// Reference: https://developer.apple.com/documentation/speech/sfspeechrecognitiontask/error
enum LSRError: Int {
    /// Assets are not installed.
    case assetsNotInstalled = 102
    /// Siri or Dictation is disabled in Settings.
    case siriDisabled = 201
    /// Failed to initialize recognizer.
    case initializationFailed = 300
    /// Request was canceled — normal lifecycle.
    case cancelled = 301
}

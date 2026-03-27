import Foundation

enum SpeechRecordingError: Error, Sendable {
    case permissionDenied
    case recognizerUnavailable
    case audioSessionFailed(any Error)
    case recognitionFailed(any Error)
}

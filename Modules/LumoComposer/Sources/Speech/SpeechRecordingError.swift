import Foundation

enum SpeechRecordingError: Error, Sendable {
    case permissionDenied
    case audioSessionFailed(any Error)
    case recognitionFailed(any Error)
}

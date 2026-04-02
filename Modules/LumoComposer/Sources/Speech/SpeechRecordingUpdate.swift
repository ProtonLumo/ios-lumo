import Foundation

enum SpeechRecordingUpdate: Sendable {
    case transcriptionUpdated(String)
    case audioLevelsUpdated([CGFloat])
    case isOnDeviceChanged(Bool)
    case failed(SpeechRecordingError)
}

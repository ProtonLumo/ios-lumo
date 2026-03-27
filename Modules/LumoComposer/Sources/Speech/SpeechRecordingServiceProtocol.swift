import Foundation

@MainActor
protocol SpeechRecordingServiceProtocol: AnyObject, Sendable {
    var updates: AsyncStream<SpeechRecordingUpdate> { get }

    func requestPermissions() async -> SpeechPermissionResult
    func startRecording() async throws
    func stopRecording() async
    func cancel()
}

@testable import LumoComposer

@MainActor
final class SpeechRecordingServiceSpy: SpeechRecordingServiceProtocol {
    private let _continuation: AsyncStream<SpeechRecordingUpdate>.Continuation
    private let _stream: AsyncStream<SpeechRecordingUpdate>

    var stubbedRequestPermissionsResult: SpeechPermissionResult = .granted
    var stubbedStartRecordingError: (any Error)?

    private(set) var startRecordingCallCount = 0
    private(set) var stopRecordingCallCount = 0
    private(set) var cancelCallCount = 0

    init() {
        let (stream, continuation) = AsyncStream<SpeechRecordingUpdate>.makeStream()
        _stream = stream
        _continuation = continuation
    }

    // MARK: - SpeechRecordingServiceProtocol

    var updates: AsyncStream<SpeechRecordingUpdate> {
        _stream
    }

    func requestPermissions() async -> SpeechPermissionResult {
        stubbedRequestPermissionsResult
    }

    func startRecording() async throws {
        startRecordingCallCount += 1
        if let error = stubbedStartRecordingError {
            throw error
        }
    }

    func stopRecording() async {
        stopRecordingCallCount += 1
    }

    func cancel() {
        cancelCallCount += 1
    }

    // MARK: - Spy

    func simulateUpdate(_ update: SpeechRecordingUpdate) {
        _continuation.yield(update)
    }

    func simulateFinishStream() {
        _continuation.finish()
    }
}

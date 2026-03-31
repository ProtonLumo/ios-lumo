import Combine
import Foundation
import Testing

@testable import LumoComposer

@MainActor
final class SpeechStateStoreTests {
    let spy = SpeechRecordingServiceSpy()
    let urlOpener = URLOpenerSpy()
    lazy var sut = SpeechStateStore(service: spy, urlOpener: urlOpener)

    // MARK: - startRecording

    @Test
    func startRecording_WhenPermissionGranted_TransitionsToRecording() async {
        spy.stubbedRequestPermissionsResult = .granted

        await sut.send(action: .startRecording)

        #expect(sut.state == .recording(.initial))
        #expect(spy.startRecordingCallCount == 1)
    }

    @Test
    func startRecording_WhenPermissionDenied_TransitionsToPermissionDenied() async {
        spy.stubbedRequestPermissionsResult = .denied

        await sut.send(action: .startRecording)

        #expect(sut.state == .permissionDenied)
        #expect(spy.startRecordingCallCount == 0)
    }

    @Test
    func startRecording_WhenPermissionRestricted_TransitionsToPermissionDenied() async {
        spy.stubbedRequestPermissionsResult = .restricted

        await sut.send(action: .startRecording)

        #expect(sut.state == .permissionDenied)
        #expect(spy.startRecordingCallCount == 0)
    }

    @Test
    func startRecording_WhenServiceThrows_RemainsIdle() async {
        spy.stubbedStartRecordingError = NSError(domain: "test", code: -1)

        await sut.send(action: .startRecording)

        #expect(sut.state == .idle)
    }

    // MARK: - Stream updates

    @Test
    func transcriptionUpdated_UpdatesRecordingViewState() async {
        await startRecordingSuccessfully()

        spy.simulateUpdate(.transcriptionUpdated("hello world"))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.state.recordingViewState?.transcription == "hello world")
    }

    @Test
    func audioLevelsUpdated_UpdatesRecordingViewState() async {
        await startRecordingSuccessfully()

        let levels: [CGFloat] = Array(repeating: 0.5, count: 30)
        spy.simulateUpdate(.audioLevelsUpdated(levels))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.state.recordingViewState?.audioLevels == levels)
    }

    @Test
    func isOnDeviceChanged_UpdatesRecordingViewState() async {
        await startRecordingSuccessfully()

        spy.simulateUpdate(.isOnDeviceChanged(true))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.state.recordingViewState?.isOnDevice == true)
    }

    // MARK: - submitRecording

    @Test
    func submitRecording_TransitionsToSubmittingThenIdle() async {
        await startRecordingSuccessfully()

        spy.simulateUpdate(.transcriptionUpdated("hello"))
        try? await Task.sleep(for: .milliseconds(50))

        var completedText: String?
        sut.onTranscriptionComplete = { text in
            completedText = text
        }

        await sut.send(action: .submitRecording)

        #expect(completedText == "hello")
        #expect(sut.state == .idle)
        #expect(spy.stopRecordingCallCount == 1)
    }

    @Test
    func submitRecording_StateIsSubmittingDuringAsyncCompletion() async {
        await startRecordingSuccessfully()

        spy.simulateUpdate(.transcriptionUpdated("hello"))
        try? await Task.sleep(for: .milliseconds(50))

        var statesDuringCompletion: [SpeechStateStore.State] = []

        sut.onTranscriptionComplete = { [weak sut] _ in
            if let state = sut?.state {
                statesDuringCompletion.append(state)
            }
            try? await Task.sleep(for: .milliseconds(50))
        }

        await sut.send(action: .submitRecording)

        #expect(statesDuringCompletion.count == 1)
        if case .submitting(let viewState) = statesDuringCompletion.first {
            #expect(viewState.transcription == "hello")
        } else {
            Issue.record("Expected .submitting state during completion, got \(String(describing: statesDuringCompletion.first))")
        }
        #expect(sut.state == .idle)
    }

    @Test
    func submitRecording_WhenNotRecording_DoesNothing() async {
        #expect(sut.state == .idle)

        await sut.send(action: .submitRecording)

        #expect(sut.state == .idle)
        #expect(spy.stopRecordingCallCount == 0)
    }

    // MARK: - cancelRecording

    @Test
    func cancelRecording_TransitionsToIdleAndCancelsService() async {
        await startRecordingSuccessfully()

        await sut.send(action: .cancelRecording)

        #expect(sut.state == .idle)
        #expect(spy.cancelCallCount == 1)
    }

    // MARK: - openSettings

    @Test
    func openSettings_OpensSettingsURL() async {
        await sut.send(action: .openSettings)

        #expect(urlOpener.callAsFunctionInvokedWithURL == [.settings])
    }

    // MARK: - dismissPermissionAlert

    @Test
    func dismissPermissionAlert_TransitionsToIdle() async {
        spy.stubbedRequestPermissionsResult = .denied
        await sut.send(action: .startRecording)
        #expect(sut.state == .permissionDenied)

        await sut.send(action: .dismissPermissionAlert)

        #expect(sut.state == .idle)
    }

    // MARK: - Service failures during recording

    @Test
    func failedPermissionDenied_TransitionsToPermissionDenied() async {
        await startRecordingSuccessfully()

        spy.simulateUpdate(.failed(.permissionDenied))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.state == .permissionDenied)
        #expect(spy.cancelCallCount == 1)
    }

    @Test
    func failedRecognitionError_TransitionsToIdle() async {
        await startRecordingSuccessfully()

        spy.simulateUpdate(.failed(.recognitionFailed(NSError(domain: "test", code: -1))))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.state == .idle)
        #expect(spy.cancelCallCount == 1)
    }

    @Test
    func failedRecognizerUnavailable_TransitionsToIdle() async {
        await startRecordingSuccessfully()

        spy.simulateUpdate(.failed(.recognizerUnavailable))
        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.state == .idle)
        #expect(spy.cancelCallCount == 1)
    }

    // MARK: - Edge cases

    @Test
    func submitRecording_WithoutOnTranscriptionComplete_DoesNotCrash() async {
        await startRecordingSuccessfully()
        sut.onTranscriptionComplete = nil

        await sut.send(action: .submitRecording)

        #expect(sut.state == .idle)
        #expect(spy.stopRecordingCallCount == 1)
    }

    @Test
    func cancelRecording_WhenIdle_DoesNothing() async {
        #expect(sut.state == .idle)

        await sut.send(action: .cancelRecording)

        #expect(sut.state == .idle)
    }

    @Test
    func internalActions_WhenNotRecording_AreIgnored() async {
        #expect(sut.state == .idle)

        await sut.send(action: ._transcriptionUpdated("ignored"))
        await sut.send(action: ._audioLevelsUpdated([]))
        await sut.send(action: ._durationTick)
        await sut.send(action: ._isOnDeviceChanged(true))

        #expect(sut.state == .idle)
    }

    // MARK: - Duration tick

    @Test
    func durationTick_IncrementsDuration() async {
        await startRecordingSuccessfully()

        await sut.send(action: ._durationTick)
        await sut.send(action: ._durationTick)
        await sut.send(action: ._durationTick)

        #expect(sut.state.recordingViewState?.duration == 3)
    }

    // MARK: - State helpers

    @Test
    func stateHelpers_IsActive() {
        #expect(SpeechStateStore.State.idle.isActive == false)
        #expect(SpeechStateStore.State.permissionDenied.isActive == false)
        #expect(SpeechStateStore.State.recording(.initial).isActive == true)
        #expect(SpeechStateStore.State.submitting(.initial).isActive == true)
    }

    @Test
    func stateHelpers_IsPermissionDenied() {
        #expect(SpeechStateStore.State.idle.isPermissionDenied == false)
        #expect(SpeechStateStore.State.permissionDenied.isPermissionDenied == true)
        #expect(SpeechStateStore.State.recording(.initial).isPermissionDenied == false)
    }

    @Test
    func stateHelpers_RecordingViewState() {
        let viewState = RecordingViewState.initial.copy(\.transcription, to: "test")
        #expect(SpeechStateStore.State.idle.recordingViewState == nil)
        #expect(SpeechStateStore.State.permissionDenied.recordingViewState == nil)
        #expect(SpeechStateStore.State.recording(viewState).recordingViewState == viewState)
        #expect(SpeechStateStore.State.submitting(viewState).recordingViewState == viewState)
    }

    // MARK: - Private helpers

    private func startRecordingSuccessfully() async {
        spy.stubbedRequestPermissionsResult = .granted

        await sut.send(action: .startRecording)
    }
}

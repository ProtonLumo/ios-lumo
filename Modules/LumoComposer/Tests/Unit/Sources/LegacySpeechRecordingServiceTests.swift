import AVFoundation
import Foundation
import Testing

@testable import LumoComposer

@MainActor
final class LegacySpeechRecordingServiceTests {
    let audioSession = AudioSessionSpy()
    let recognizerSpy = SpeechRecognizerSpy()
    let engineSpy = AudioEngineSpy()

    private func makeSUT(
        audioApplication: AudioApplication.Type = AudioApplicationGrantedStub.self,
        speechAuthorization: SpeechAuthorizationProviding.Type = SpeechAuthorizationAuthorizedStub.self,
        speechRecognizerFactory: LegacySpeechRecordingService.SpeechRecognizerFactory? = nil
    ) -> LegacySpeechRecordingService {
        LegacySpeechRecordingService(
            audioSession: audioSession,
            audioApplication: audioApplication,
            speechAuthorization: speechAuthorization,
            speechRecognizerFactory: speechRecognizerFactory ?? { [recognizerSpy] _ in recognizerSpy },
            audioEngine: engineSpy
        )
    }

    // MARK: - requestPermissions

    @Test
    func requestPermissions_whenBothGranted_returnsGranted() async {
        let sut = makeSUT()
        let result = await sut.requestPermissions()
        #expect(result == .granted)
    }

    @Test
    func requestPermissions_whenSpeechDenied_returnsDenied() async {
        let sut = makeSUT(speechAuthorization: SpeechAuthorizationDeniedStub.self)
        let result = await sut.requestPermissions()
        #expect(result == .denied)
    }

    @Test
    func requestPermissions_whenSpeechRestricted_returnsRestricted() async {
        let sut = makeSUT(speechAuthorization: SpeechAuthorizationRestrictedStub.self)
        let result = await sut.requestPermissions()
        #expect(result == .restricted)
    }

    @Test
    func requestPermissions_whenMicDenied_returnsDenied() async {
        let sut = makeSUT(audioApplication: AudioApplicationDeniedStub.self)
        let result = await sut.requestPermissions()
        #expect(result == .denied)
    }

    // MARK: - startRecording — audio session

    @Test
    func startRecording_configuresAudioSession() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        #expect(
            audioSession.setCategoryCalls == [
                .init(
                    category: .playAndRecord,
                    mode: .spokenAudio,
                    options: [.defaultToSpeaker, .allowBluetoothHFP])
            ]
        )
        #expect(
            audioSession.setActiveCalls == [
                .init(active: true, options: .notifyOthersOnDeactivation)
            ])
        #expect(audioSession.setPreferredSampleRateCalls == [16000.0])
        #expect(audioSession.setPreferredIOBufferDurationCalls == [0.01])
    }

    @Test
    func startRecording_whenAudioSessionFails_throwsAndEmitsFailure() async {
        audioSession.stubbedSetCategoryError = NSError(domain: "test", code: -1)

        let sut = makeSUT()

        var receivedUpdate: SpeechRecordingUpdate?
        do {
            try await sut.startRecording()
            Issue.record("Expected throw")
        } catch {
            for await update in sut.updates {
                receivedUpdate = update
                break
            }
        }

        guard case .failed(.audioSessionFailed) = receivedUpdate else {
            Issue.record("Expected .failed(.audioSessionFailed), got \(String(describing: receivedUpdate))")
            return
        }
    }

    // MARK: - startRecording — recognizer

    @Test
    func startRecording_emitsIsOnDeviceChanged() async throws {
        recognizerSpy.supportsOnDeviceRecognition = true

        let sut = makeSUT()

        try await sut.startRecording()

        let update = await firstUpdate(from: sut)
        guard case .isOnDeviceChanged(true) = update else {
            Issue.record("Expected .isOnDeviceChanged(true), got \(String(describing: update))")
            return
        }
    }

    @Test
    func startRecording_whenRecognizerNil_emitsRecognizerUnavailable() async throws {
        let sut = makeSUT(speechRecognizerFactory: { _ in nil })

        try await sut.startRecording()

        let updates = await collectUpdates(from: sut, count: 2)
        let hasUnavailable = updates.contains {
            if case .failed(.recognizerUnavailable) = $0 { return true }
            return false
        }
        #expect(hasUnavailable)
    }

    // MARK: - startRecording — audio engine

    @Test
    func startRecording_preparesAndStartsEngine() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        #expect(engineSpy.prepareCalled)
        #expect(engineSpy.startCalled)
        #expect(engineSpy.tapBlock != nil)
    }

    @Test
    func startRecording_whenEngineStartFails_throws() async {
        engineSpy.stubbedStartError = NSError(domain: "test", code: -1)

        let sut = makeSUT()

        do {
            try await sut.startRecording()
            Issue.record("Expected throw")
        } catch {
            // Expected
        }
    }

    // MARK: - Recognition results via stream

    @Test
    func startRecording_recognitionResult_emitsTranscription() async throws {
        let sut = makeSUT()
        try await sut.startRecording()

        recognizerSpy.simulateResult("hello world")
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .transcriptionUpdated("hello world") = update else {
            Issue.record("Expected .transcriptionUpdated, got \(String(describing: update))")
            return
        }
    }

    @Test
    func startRecording_siriDisabled_emitsPermissionDenied() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        recognizerSpy.simulateError(NSError(domain: "kLSRErrorDomain", code: 201))
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .failed(.permissionDenied) = update else {
            Issue.record("Expected .failed(.permissionDenied), got \(String(describing: update))")
            return
        }
    }

    @Test
    func startRecording_requestCancelled_isIgnored() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        recognizerSpy.simulateError(NSError(domain: "kLSRErrorDomain", code: 301))
        recognizerSpy.simulateResult("continuing")
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .transcriptionUpdated("continuing") = update else {
            Issue.record("Expected .transcriptionUpdated, got \(String(describing: update))")
            return
        }
    }

    @Test
    func startRecording_noSpeechDetected_isIgnored() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        recognizerSpy.simulateError(NSError(domain: "kAFAssistantErrorDomain", code: 1110))
        recognizerSpy.simulateResult("continuing")
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .transcriptionUpdated("continuing") = update else {
            Issue.record("Expected .transcriptionUpdated, got \(String(describing: update))")
            return
        }
    }

    @Test
    func startRecording_connectionInterrupted_isIgnored() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        recognizerSpy.simulateError(NSError(domain: "kAFAssistantErrorDomain", code: 1107))
        recognizerSpy.simulateResult("continuing")
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .transcriptionUpdated("continuing") = update else {
            Issue.record("Expected .transcriptionUpdated, got \(String(describing: update))")
            return
        }
    }

    @Test
    func startRecording_notAuthorized_emitsPermissionDenied() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        recognizerSpy.simulateError(NSError(domain: "kAFAssistantErrorDomain", code: 1700))
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .failed(.permissionDenied) = update else {
            Issue.record("Expected .failed(.permissionDenied), got \(String(describing: update))")
            return
        }
    }

    /// Verifies that unknown errors are ignored when a transcription result is present.
    /// Uses SpeechStateStore as stream observer: if `.failed` were emitted, store would transition to `.idle`.
    @Test
    func startRecording_unknownErrorWithResult_errorIsIgnored() async throws {
        let service = makeSUT()

        let store = SpeechStateStore(service: service)

        await store.send(action: .startRecording)
        try await Task.sleep(for: .milliseconds(50))

        recognizerSpy.simulateResultWithError(text: "partial", error: NSError(domain: "unknown", code: 999))
        try await Task.sleep(for: .milliseconds(50))

        // If error was ignored → store stays in .recording with transcription
        // If error was NOT ignored → store transitions to .idle via ._failed
        guard case .recording(let viewState) = store.state else {
            Issue.record("Expected .recording but got \(store.state) — error was not ignored")
            return
        }
        #expect(viewState.transcription == "partial")
    }

    @Test
    func startRecording_unknownErrorWithoutResult_emitsRecognitionFailed() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        recognizerSpy.simulateError(NSError(domain: "unknown", code: 999))
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .failed(.recognitionFailed) = update else {
            Issue.record("Expected .failed(.recognitionFailed), got \(String(describing: update))")
            return
        }
    }

    // MARK: - Audio levels via buffer

    @Test
    func startRecording_audioBuffer_emitsAudioLevels() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        let buffer = makeTestBuffer(amplitude: 0.5)
        engineSpy.simulateTapBlock(buffer)
        try? await Task.sleep(for: .milliseconds(50))

        let update = await firstUpdate(from: sut, skippingOnDeviceChanged: true)
        guard case .audioLevelsUpdated(let levels) = update else {
            Issue.record("Expected .audioLevelsUpdated, got \(String(describing: update))")
            return
        }
        #expect(levels.count == 30)
    }

    // MARK: - cancel

    @Test
    func cancel_stopsEngineAndDeactivatesSession() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        sut.cancel()

        #expect(engineSpy.stopCalled)
        #expect(
            audioSession.setActiveCalls == [
                .init(active: true, options: .notifyOthersOnDeactivation),
                .init(active: false, options: .notifyOthersOnDeactivation)
            ]
        )
    }

    // MARK: - stopRecording

    @Test
    func stopRecording_stopsEngineAndDeactivatesSession() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        await sut.stopRecording()

        #expect(engineSpy.stopCalled)
        #expect(
            audioSession.setActiveCalls == [
                .init(active: true, options: .notifyOthersOnDeactivation),
                .init(active: false, options: .notifyOthersOnDeactivation)
            ]
        )
    }

    // MARK: - Sequential start without stop

    @Test
    func startRecording_calledTwice_doesNotCrash() async throws {
        let sut = makeSUT()

        try await sut.startRecording()

        engineSpy.isRunning = true

        try await sut.startRecording()

        #expect(engineSpy.startCalled)
    }

    // MARK: - Helpers

    private func firstUpdate(
        from sut: LegacySpeechRecordingService,
        skippingOnDeviceChanged: Bool = false
    ) async -> SpeechRecordingUpdate? {
        for await update in sut.updates {
            if skippingOnDeviceChanged, case .isOnDeviceChanged = update { continue }
            return update
        }
        return nil
    }

    private func collectUpdates(
        from sut: LegacySpeechRecordingService,
        count: Int
    ) async -> [SpeechRecordingUpdate] {
        var updates: [SpeechRecordingUpdate] = []
        for await update in sut.updates {
            updates.append(update)
            if updates.count >= count {
                break
            }
        }
        return updates
    }

    private func makeTestBuffer(amplitude: Float, frameCount: Int = 1024) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        let channelData = buffer.floatChannelData!.pointee
        for i in 0..<frameCount {
            channelData[i] = amplitude
        }
        return buffer
    }
}

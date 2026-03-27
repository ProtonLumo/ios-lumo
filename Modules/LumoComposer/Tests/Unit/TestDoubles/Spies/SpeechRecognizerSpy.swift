import AVFoundation
import Speech

@testable import LumoComposer

@MainActor
final class SpeechRecognizerSpy: SpeechRecognizerProviding {
    let stubbedRecognictionTask = SpeechRecognitionTaskSpy()

    var supportsOnDeviceRecognition = false
    private(set) var resultHandler: (@Sendable (String?, Error?) -> Void)?

    func recognitionTask(
        with request: SFSpeechAudioBufferRecognitionRequest,
        resultHandler: @escaping @Sendable (String?, Error?) -> Void
    ) -> any SpeechRecognitionTask {
        self.resultHandler = resultHandler
        return stubbedRecognictionTask
    }

    // MARK: - Spy interface

    func simulateResult(_ text: String) {
        resultHandler?(text, nil)
    }

    func simulateError(_ error: Error) {
        resultHandler?(nil, error)
    }

    func simulateResultWithError(text: String, error: Error) {
        resultHandler?(text, error)
    }
}

final class SpeechRecognitionTaskSpy: SpeechRecognitionTask {
    private(set) var finishCalled = false
    private(set) var cancelCalled = false

    func finish() {
        finishCalled = true
    }

    func cancel() {
        cancelCalled = true
    }
}

@testable import LumoComposer

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

import Speech

protocol SpeechRecognitionTask {
    func finish()
    func cancel()
}

extension SFSpeechRecognitionTask: SpeechRecognitionTask {}

@MainActor
protocol SpeechRecognizerProviding {
    var supportsOnDeviceRecognition: Bool { get }

    func recognitionTask(
        with request: SFSpeechAudioBufferRecognitionRequest,
        resultHandler: @escaping @Sendable (String?, Error?) -> Void
    ) -> any SpeechRecognitionTask
}

@MainActor
final class SFSpeechRecognizerAdapter: SpeechRecognizerProviding {
    private let recognizer: SFSpeechRecognizer

    init(recognizer: SFSpeechRecognizer) {
        self.recognizer = recognizer
        recognizer.defaultTaskHint = .dictation
    }

    var supportsOnDeviceRecognition: Bool {
        recognizer.supportsOnDeviceRecognition
    }

    func recognitionTask(
        with request: SFSpeechAudioBufferRecognitionRequest,
        resultHandler: @escaping @Sendable (String?, Error?) -> Void
    ) -> any SpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            resultHandler(result?.bestTranscription.formattedString, error)
        }
    }
}

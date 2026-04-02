import Speech

protocol SpeechAuthorizationProviding {
    static func requestAuthorization(_ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void)
}

extension SFSpeechRecognizer: SpeechAuthorizationProviding {}

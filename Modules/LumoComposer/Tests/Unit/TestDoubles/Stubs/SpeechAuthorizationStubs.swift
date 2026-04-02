import Speech

@testable import LumoComposer

enum SpeechAuthorizationAuthorizedStub: SpeechAuthorizationProviding {
    static func requestAuthorization(
        _ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void
    ) {
        handler(.authorized)
    }
}

enum SpeechAuthorizationDeniedStub: SpeechAuthorizationProviding {
    static func requestAuthorization(
        _ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void
    ) {
        handler(.denied)
    }
}

enum SpeechAuthorizationRestrictedStub: SpeechAuthorizationProviding {
    static func requestAuthorization(
        _ handler: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void
    ) {
        handler(.restricted)
    }
}

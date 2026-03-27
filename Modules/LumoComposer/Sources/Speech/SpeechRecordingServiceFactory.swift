enum SpeechRecordingServiceFactory {
    @MainActor
    static func make() -> any SpeechRecordingServiceProtocol {
        LegacySpeechRecordingService()
    }
}

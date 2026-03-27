import Speech

enum SFSpeechRecognizerAdapterFactory {
    /// Creates an adapter for the given locale, falling back to `en-US` if unsupported.
    @MainActor
    static func make(locale: Locale) -> SpeechRecognizerProviding? {
        let fallbackLocale = Locale(identifier: "en-US")
        let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: fallbackLocale)

        guard let recognizer else { return nil }
        return SFSpeechRecognizerAdapter(recognizer: recognizer)
    }
}

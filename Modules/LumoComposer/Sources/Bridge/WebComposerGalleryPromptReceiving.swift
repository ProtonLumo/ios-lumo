/// Protocol for receiving gallery prompt injections from the WebView's JavaScript layer.
///
/// Handles the `injectImageGenerationHelperPrompt` callback from the web application to Swift,
/// triggered when the user taps a style in the image generation gallery. The web sends a
/// pre-defined prompt string that should be injected into the native composer.
public protocol WebComposerGalleryPromptReceiving {
    /// Processes a gallery prompt received from the WebView.
    ///
    /// **Data flow:** JavaScript → WKScriptMessage → String → AsyncStream
    ///
    /// - Parameter prompt: The pre-defined prompt string from the gallery style selection
    func handleGalleryPrompt(_ prompt: String)
}

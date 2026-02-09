import WebKit

/// Protocol for communication with WebView
protocol WebComposerBridging {
    /// Set up communication with the WebView
    ///
    /// Must be called before using other bridge methods.
    ///
    /// - Parameter webView: The WKWebView to communicate with
    func attach(to webView: WKWebView)

    /// Send a prompt to Lumo
    /// - Parameter text: The prompt text to send
    func sendPrompt(_ text: String) async throws

    /// Stop the current response generation
    func stopResponse() async throws

    /// Toggle web search on/off
    func toggleWebSearch() async throws

    /// Open file picker in WebView
    func openFilePicker() async throws

    /// Remove an attachment
    /// - Parameter id: Attachment identifier
    func removeAttachment(id: String) async throws

    /// Preview an attachment
    /// - Parameter id: Attachment identifier
    func previewAttachment(id: String) async throws

    /// Stream of state updates from WebView
    var stateUpdates: AsyncStream<WebComposerState> { get }
}

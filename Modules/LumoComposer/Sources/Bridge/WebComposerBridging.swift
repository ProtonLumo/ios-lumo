import WebKit

/// Protocol for sending commands to the WebView's JavaScript layer.
///
/// Handles outbound communication from Swift to the web application.
/// Complements `WebComposerStateReceiving` which handles inbound communication (JavaScript → Swift).
protocol WebComposerBridging {
    /// Send a prompt to Lumo
    /// - Parameter text: The prompt text to send
    func sendPrompt(_ text: String) async throws(WebComposerBridgeError)

    /// Stop the current response generation
    func stopResponse() async throws(WebComposerBridgeError)

    /// Toggle web search on/off
    func toggleWebSearch() async throws(WebComposerBridgeError)

    /// Open file picker in WebView
    func openFilePicker() async throws(WebComposerBridgeError)

    /// Remove an attachment
    /// - Parameter id: Attachment identifier
    func removeAttachment(id: String) async throws(WebComposerBridgeError)

    /// Preview an attachment
    /// - Parameter id: Attachment identifier
    func previewAttachment(id: String) async throws(WebComposerBridgeError)

    /// Stream of state updates from WebView
    var stateUpdates: AsyncStream<WebComposerState> { get }
}

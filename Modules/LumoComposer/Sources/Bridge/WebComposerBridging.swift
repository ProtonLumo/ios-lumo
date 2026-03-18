import WebKit

/// Protocol for sending commands to the WebView's JavaScript layer.
///
/// Handles outbound communication from Swift to the web application.
/// Complements `WebComposerStateReceiving` which handles inbound communication (JavaScript → Swift).
public protocol WebComposerBridging {
    /// Send a prompt to Lumo
    /// - Parameter text: The prompt text to send
    func sendPrompt(_ text: String) async throws(WebComposerBridgeError)

    /// Stop the current response generation
    func stopResponse() async throws(WebComposerBridgeError)

    /// Toggle web search on/off
    func toggleWebSearch() async throws(WebComposerBridgeError)

    /// Upload files from native to web
    /// - Parameter files: Array of files with base64 data and names
    func uploadFiles(_ files: [FileUploadData]) async throws(WebComposerBridgeError)

    /// Open Proton Drive file picker
    func openProtonDrive() async throws(WebComposerBridgeError)

    /// Open sketch/drawing interface
    func openSketch() async throws(WebComposerBridgeError)

    /// Toggle image generation
    func toggleCreateImage() async throws(WebComposerBridgeError)

    /// Change model tier
    /// - Parameter model: The model tier to use
    func changeModelTier(_ model: WebComposerState.ModelTier) async throws(WebComposerBridgeError)

    /// Remove an attachment
    /// - Parameter id: Attachment identifier
    func removeAttachment(id: String) async throws(WebComposerBridgeError)

    /// Preview an attachment
    /// - Parameter id: Attachment identifier
    func previewAttachment(id: String) async throws(WebComposerBridgeError)

    /// Stream of state updates from WebView
    var stateUpdates: AsyncStream<WebComposerState> { get }

    /// Stream of errors received from WebView
    var errorUpdates: AsyncStream<WebComposerError> { get }
}

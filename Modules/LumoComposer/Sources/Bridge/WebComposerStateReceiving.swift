/// Protocol for receiving state updates from the WebView's JavaScript layer.
///
/// Handles inbound communication from the web application to Swift.
/// Complements `WebComposerBridging` which handles outbound communication (Swift → JavaScript).
public protocol WebComposerStateReceiving {
    /// Processes state updates received from the WebView.
    ///
    /// **Data flow:** JavaScript → WKScriptMessage → Dictionary → `WebComposerState` → AsyncStream
    ///
    /// - Parameter state: Raw state dictionary from JavaScript
    func handleStateChange(state: [String: Any])
}

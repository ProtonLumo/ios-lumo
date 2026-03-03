/// Protocol for receiving error notifications from the WebView's JavaScript layer.
///
/// Handles error callbacks from the web application to Swift.
public protocol WebComposerErrorReceiving {
    /// Processes error result received from the WebView.
    ///
    /// **Data flow:** JavaScript → sendResultToNative → WKScriptMessage → Error Handler
    ///
    /// - Parameter errorResponse: Raw error response dictionary from JavaScript
    func handleError(_ errorResponse: [String: Any])
}

import WebKit

/// Abstraction over WKWebView for JavaScript evaluation.
///
/// Enables testability by allowing mock implementations of WebView functionality.
public protocol WebViewProtocol: AnyObject {
    /// Evaluates JavaScript code in the WebView.
    ///
    /// - Parameters:
    ///   - javaScript: JavaScript code to execute
    ///   - frame: Frame in which to evaluate (nil for main frame)
    ///   - contentWorld: Content world for isolation
    /// - Returns: Result of the JavaScript evaluation
    /// - Throws: Error if evaluation fails
    @discardableResult
    func evaluateJavaScript(
        _ javaScript: String,
        in frame: WKFrameInfo?,
        contentWorld: WKContentWorld
    ) async throws -> Any?
}

extension WKWebView: WebViewProtocol {}

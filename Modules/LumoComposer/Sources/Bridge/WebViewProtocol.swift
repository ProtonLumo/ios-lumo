import WebKit

protocol WebViewProtocol: AnyObject {
    func evaluateJavaScript(
        _ javaScript: String,
        in frame: WKFrameInfo?,
        contentWorld: WKContentWorld
    ) async throws -> Any?
}

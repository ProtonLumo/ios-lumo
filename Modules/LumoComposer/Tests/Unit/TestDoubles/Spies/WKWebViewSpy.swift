import WebKit

@testable import LumoComposer

final class WKWebViewSpy: WebViewProtocol {
    struct Params: Equatable {
        let javaScript: String
        let frame: WKFrameInfo?
        let contentWorld: WKContentWorld
    }

    var stubbedError: Error?

    private(set) var evaluateJavaScriptCalls: [Params] = []

    // MARK: - WebViewProtocol

    func evaluateJavaScript(
        _ javaScript: String,
        in frame: WKFrameInfo?,
        contentWorld: WKContentWorld
    ) async throws -> Any? {
        let params = Params(javaScript: javaScript, frame: frame, contentWorld: contentWorld)

        evaluateJavaScriptCalls.append(params)

        if let stubbedError {
            throw stubbedError
        }

        return nil
    }
}

import LumoCore
import WebKit

/// Errors that can occur during bridge operations.
enum WebComposerBridgeError: Error, Equatable {
    /// JavaScript evaluation failed for the given command
    case evaluatingJSFailed(WebComposerBridge.Command)

    /// WebView is not attached - call `attach(to:)` first
    case webViewNotAttached
}

final class WebComposerBridge: WebComposerAttaching, WebComposerBridging, WebComposerStateReceiving {
    private let (stream, continuation) = AsyncStream.makeStream(of: WebComposerState.self)

    /// Commands that can be sent to the WebView's JavaScript layer.
    enum Command: Equatable {
        case sendPrompt(String)
        case stopResponse
        case openFilePicker
        case toggleWebSearch
        case previewAttachment(id: String)
        case removeAttachment(id: String)

        /// JavaScript code to execute for this command.
        ///
        /// Generates a call to `window.nativeComposerApi` with a unique request ID.
        var rawString: String {
            let id = UUIDEnvironment.uuid().uuidString

            switch self {
            case .sendPrompt(let prompt):
                return "window.nativeComposerApi?.sendPrompt('\(id)', '\(prompt)');"
            case .stopResponse:
                return "window.nativeComposerApi?.abortPrompt('\(id)');"
            case .openFilePicker:
                return "window.nativeComposerApi?.onAttachClick('\(id)');"
            case .toggleWebSearch:
                return "window.nativeComposerApi?.toggleWebSearch('\(id)');"
            case .previewAttachment(let attachmentId):
                return "window.nativeComposerApi?.previewFile('\(id)', '\(attachmentId)');"
            case .removeAttachment(let attachmentId):
                return "window.nativeComposerApi?.removeFileEvent('\(id)', '\(attachmentId)');"
            }
        }
    }

    weak var webView: WebViewProtocol?

    // MARK: - WebComposerAttaching

    func attach(to webView: WebViewProtocol) {
        self.webView = webView
    }

    // MARK: - WebComposerBridging

    func sendPrompt(_ text: String) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.sendPrompt(text.jsEscaped))
    }

    func stopResponse() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.stopResponse)
    }

    func toggleWebSearch() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.toggleWebSearch)
    }

    func openFilePicker() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.openFilePicker)
    }

    func removeAttachment(id: String) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.removeAttachment(id: id))
    }

    func previewAttachment(id: String) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.previewAttachment(id: id))
    }

    var stateUpdates: AsyncStream<WebComposerState> { stream }

    // MARK: - WebComposerStateReceiving

    /// Processes state updates received from the WebView's JavaScript layer.
    ///
    /// **Data flow:** JavaScript → WKScriptMessage → Dictionary → `WebComposerState` → AsyncStream
    ///
    /// Decoding failures are silently ignored to maintain stable bridge communication.
    func handleStateChange(state: [String: Any]) {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: state),
            let webState = try? JSONDecoder().decode(WebComposerState.self, from: jsonData)
        else {
            return
        }

        continuation.yield(webState)
    }

    // MARK: - Private

    /// Executes a JavaScript command in the attached WebView.
    ///
    /// - Parameter command: Command to execute
    /// - Throws: `WebComposerBridgeError` if WebView not attached or execution fails
    private func executeJavaScript(_ command: Command) async throws(WebComposerBridgeError) {
        guard let webView else {
            throw .webViewNotAttached
        }

        do {
            try await webView.evaluateJavaScript(
                command.rawString,
                in: .none,
                contentWorld: .page
            )
        } catch {
            throw .evaluatingJSFailed(command)
        }
    }
}

import LumoCore
import WebKit

enum WebComposerBridgeError: Error, Equatable {
    case webViewNotAttached
    case evaluatingJSFailed(WebComposerBridge.Command)
}

final class WebComposerBridge: WebComposerAttaching, WebComposerBridging {
    enum Command: Equatable {
        case sendPrompt(String)
        case stopResponse
        case openFilePicker
        case toggleWebSearch
        case previewAttachment(id: String)
        case removeAttachment(id: String)

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

    var stateUpdates: AsyncStream<WebComposerState> {
        fatalError()  // FIXME: Implement
    }

    // MARK: - Private

    private func executeJavaScript(_ command: Command) async throws(WebComposerBridgeError) {
        guard let webView else {
            throw .webViewNotAttached
        }

        do {
            let _ = try await webView.evaluateJavaScript(
                command.rawString,
                in: .none,
                contentWorld: .page
            )
        } catch {
            throw .evaluatingJSFailed(command)
        }
    }
}

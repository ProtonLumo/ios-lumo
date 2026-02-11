import WebKit

/// Message handler for receiving composer messages from JavaScript
final class WebComposerScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private let webBridge: WebComposerStateReceiving

    init(webBridge: WebComposerStateReceiving) {
        self.webBridge = webBridge
        super.init()
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "nativeComposerStateHandler":
            handleStateChange(message)
        default:
            break
        }
    }

    // MARK: - Private

    private func handleStateChange(_ message: WKScriptMessage) {
        if let dictionary = message.body as? [String: Any] {
            webBridge.handleStateChange(state: dictionary)
        }
    }
}

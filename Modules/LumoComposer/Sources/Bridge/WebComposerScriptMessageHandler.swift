import LumoCore
import WebKit

/// Message handler for receiving composer messages from JavaScript
public final class WebComposerScriptMessageHandler: NSObject, WebScriptMessageHandler {
    public init(webComposerBridge: WebComposerStateReceiving & WebComposerErrorReceiving) {
        self.webComposerBridge = webComposerBridge
        super.init()
    }

    // MARK: - WebScriptMessageHandler

    public enum MessageName: String, CaseIterable {
        case nativeComposerStateHandler
        case nativeComposerHandler
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = MessageName(rawValue: message.name)

        switch messageName {
        case .nativeComposerStateHandler:
            handleStateChange(message)
        case .nativeComposerHandler:
            handleResult(message)
        case .none:
            break
        }
    }

    // MARK: - Private

    private let webComposerBridge: WebComposerStateReceiving & WebComposerErrorReceiving

    private func handleStateChange(_ message: WKScriptMessage) {
        if let dictionary = message.body as? [String: Any] {
            webComposerBridge.handleStateChange(state: dictionary)
        }
    }

    private func handleResult(_ message: WKScriptMessage) {
        if let dictionary = message.body as? [String: Any] {
            webComposerBridge.handleError(dictionary)
        }
    }
}

import LumoCore
import WebKit

/// Message handler for receiving composer messages from JavaScript
public final class WebComposerScriptMessageHandler: NSObject, WKScriptMessageHandler, WKMessageHandlerRegistering {
    public init(webComposerBridge: WebComposerStateReceiving) {
        self.webComposerBridge = webComposerBridge
        super.init()
    }

    // MARK: - WKMessageHandlerRegistering

    public enum MessageName: String, CaseIterable {
        case nativeComposerStateHandler
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = MessageName(rawValue: message.name)

        switch messageName {
        case .nativeComposerStateHandler:
            handleStateChange(message)
        case .none:
            break
        }
    }

    // MARK: - Private

    private let webComposerBridge: WebComposerStateReceiving

    private func handleStateChange(_ message: WKScriptMessage) {
        if let dictionary = message.body as? [String: Any] {
            webComposerBridge.handleStateChange(state: dictionary)
        }
    }
}

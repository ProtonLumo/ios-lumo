import LumoCore
import WebKit

/// Message handler for receiving composer messages from JavaScript
final class WebComposerScriptMessageHandler: NSObject, WKScriptMessageHandler, WKMessageHandlerRegistering {
    enum MessageName: String, CaseIterable {
        case nativeComposerStateHandler
    }

    init(webBridge: WebComposerStateReceiving) {
        self.webBridge = webBridge
        super.init()
    }

    // MARK: - WKMessageHandlerRegistering

    func registerForAll(in configuration: WKWebViewConfiguration) {
        MessageName.allCases.forEach { message in
            configuration.userContentController.add(self, name: message.rawValue)
        }
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

    private let webBridge: WebComposerStateReceiving

    private func handleStateChange(_ message: WKScriptMessage) {
        if let dictionary = message.body as? [String: Any] {
            webBridge.handleStateChange(state: dictionary)
        }
    }
}

import WebKit

public protocol WKMessageHandlerRegistering: WKScriptMessageHandler {
    associatedtype MessageName: CaseIterable, RawRepresentable where MessageName.RawValue == String

    func registerForAll(in configuration: WKWebViewConfiguration)
}

extension WKMessageHandlerRegistering {
    public func registerForAll(in configuration: WKWebViewConfiguration) {
        MessageName.allCases.forEach { message in
            configuration.userContentController.add(self, name: message.rawValue)
        }
    }
}

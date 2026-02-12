import WebKit

public protocol WKMessageHandlerRegistering {
    func registerForAll(in configuration: WKWebViewConfiguration)
}

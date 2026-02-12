import WebKit

/// A protocol that extends `WKScriptMessageHandler` with automatic registration of all message handlers.
///
/// This protocol simplifies the registration of multiple script message handlers by automatically
/// iterating over all cases of the `MessageName` enum and registering them with the user content controller.
///
/// ## Usage
///
/// ```swift
/// final class MyMessageHandler: NSObject, WebScriptMessageHandler {
///     enum MessageName: String, CaseIterable {
///         case messageOne
///         case messageTwo
///     }
///
///     func registerForAll(in configuration: WKWebViewConfiguration) {
///         // Default implementation automatically registers all cases
///     }
///
///     func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
///         guard let messageName = MessageName(rawValue: message.name) else { return }
///         // Handle messages...
///     }
/// }
///
/// // Registration
/// let handler = MyMessageHandler()
/// handler.registerForAll(in: webViewConfiguration)
/// // Equivalent to:
/// // configuration.userContentController.add(handler, name: "messageOne")
/// // configuration.userContentController.add(handler, name: "messageTwo")
/// ```
public protocol WebScriptMessageHandler: WKScriptMessageHandler {
    /// The enum type representing all message names this handler can receive.
    ///
    /// Must be `CaseIterable` to allow automatic registration of all cases,
    /// and `RawRepresentable` with `String` raw values to match JavaScript message names.
    associatedtype MessageName: CaseIterable, RawRepresentable where MessageName.RawValue == String

    /// Registers all message handlers with the WebView configuration.
    ///
    /// - Parameter configuration: The WebView configuration to register message handlers with.
    func registerForAll(in configuration: WKWebViewConfiguration)
}

extension WebScriptMessageHandler {
    public func registerForAll(in configuration: WKWebViewConfiguration) {
        MessageName.allCases.forEach { message in
            configuration.userContentController.add(self, name: message.rawValue)
        }
    }
}

import LumoCore
import WebKit

public typealias WebComposerReceiving = WebComposerStateReceiving & WebComposerErrorReceiving & WebComposerGalleryPromptReceiving

/// Message handler for receiving composer messages from JavaScript
public final class WebComposerScriptMessageHandler: NSObject, WebScriptMessageHandler {
    public init(webComposerBridge: WebComposerReceiving) {
        self.webComposerBridge = webComposerBridge
        super.init()
    }

    // MARK: - WebScriptMessageHandler

    /// Message handler names registered with `WKUserContentController`.
    ///
    /// Each raw value must exactly match the `webkit.messageHandlers.<name>` string used on the
    /// JavaScript side in `nativeComposerBridge.ts` (web project), as WKWebView routes incoming
    /// messages by name.
    ///
    /// - `nativeComposerStateHandler`: receives full composer state updates via `sendStateToNative()`
    /// - `nativeComposerHandler`: receives API call results (request/response) via `sendResultToNative()`
    /// - `nativeComposerImageGenerationHelperPromptHandler`: receives a plain string prompt via `injectImageGenerationHelperPrompt()`
    public enum MessageName: String, CaseIterable {
        case nativeComposerStateHandler
        case nativeComposerHandler
        case nativeComposerImageGenerationHelperPromptHandler
    }

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = MessageName(rawValue: message.name)

        switch messageName {
        case .nativeComposerStateHandler:
            handleStateChange(message)
        case .nativeComposerHandler:
            handleResult(message)
        case .nativeComposerImageGenerationHelperPromptHandler:
            handleGalleryPrompt(message)
        case .none:
            break
        }
    }

    // MARK: - Private

    private let webComposerBridge: WebComposerReceiving

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

    private func handleGalleryPrompt(_ message: WKScriptMessage) {
        if let prompt = message.body as? String {
            webComposerBridge.handleGalleryPrompt(prompt)
        }
    }
}

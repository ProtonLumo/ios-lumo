import Foundation
import WebKit

/// Type-safe JavaScript commands that can be executed in the WebView
enum JSCommand {
    // MARK: - Prompt Operations
    case insertPrompt(text: String, editorType: EditorType)

    // MARK: - Payment Operations
    case getSubscriptions
    case restorePurchases
    case cancelSubscription
    case openPaymentSheet(payload: [String: Any])

    // MARK: - Theme Operations
    case readTheme
    case updateTheme(theme: String)
    case setupThemeListener

    // MARK: - Navigation & UI
    case checkElementExists(selector: String)
    case simulateGarbageCollection
    case clearHistory

    // MARK: - Setup Scripts
    case initialSetup
    case setupMessageHandlers
    case setupPromotionHandler
    case setupVoiceEntry

    /// Editor type for text insertion
    enum EditorType: String {
        case tiptap = "tiptap"
        case basic = "basic"
        case textarea = "textarea"

        var selector: String {
            switch self {
            case .tiptap, .basic:
                return ".tiptap.ProseMirror.composer, .composer"
            case .textarea:
                return "textarea.composer-textarea"
            }
        }
    }

    /// Convert command to executable JavaScript with proper escaping
    var javascript: String {
        switch self {
        case .insertPrompt(let text, let editorType):
            let safeText = text.jsEscaped
            return """
                (function() {
                    const prompt = '\(safeText)';
                    const editorType = '\(editorType.rawValue)';

                    // Use execCommand to insert text. This is the only approach that correctly
                    // manages iOS's RTI (Remote Text Input) session lifecycle:
                    //   1. focus() opens the session
                    //   2. execCommand('insertText') inserts through the native input path,
                    //      keeping React's onChange in sync via the fired input event
                    //   3. blur() closes the session cleanly
                    //
                    // All three steps run in the same synchronous JS execution, so iOS never
                    // gets a chance to show the keyboard (keyboard presentation requires
                    // yielding to the run loop).
                    //
                    // Alternatives that were tried and rejected:
                    //  - textContent mutation: breaks on 2nd call (React state not updated)
                    //  - window.__insertPromptImpl / React setState: async commit leaves the RTI
                    //    session in a stale state, causing "Result accumulator timeout" and
                    //    keyboard appearing after submit
                    let editor = null;
                    if (editorType === 'tiptap' || editorType === 'basic') {
                        editor = document.querySelector('.tiptap.ProseMirror.composer') ||
                                document.querySelector('.composer');
                    } else if (editorType === 'textarea') {
                        editor = document.querySelector('textarea.composer-textarea');
                    }

                    if (!editor) {
                        return { success: false, reason: 'editor_not_found' };
                    }

                    editor.focus();
                    document.execCommand('selectAll', false, null);
                    const inserted = document.execCommand('insertText', false, prompt);
                    editor.blur();

                    return { success: true, action: inserted ? 'execCommand' : 'execCommand_failed' };
                })();
                """

        case .getSubscriptions:
            return """
                (async function() {
                    if (window.paymentApiInstance && typeof window.paymentApiInstance.getSubscriptions === 'function') {
                        const result = await window.paymentApiInstance.getSubscriptions();
                        return { success: true, data: result };
                    }
                    return { success: false, reason: 'payment_api_not_available' };
                })();
                """

        case .restorePurchases:
            return """
                (async function() {
                    if (window.paymentApiInstance && typeof window.paymentApiInstance.restorePurchases === 'function') {
                        const result = await window.paymentApiInstance.restorePurchases();
                        return { success: true, data: result };
                    }
                    return { success: false, reason: 'payment_api_not_available' };
                })();
                """

        case .cancelSubscription:
            return """
                (async function() {
                    if (window.paymentApiInstance && typeof window.paymentApiInstance.cancelSubscription === 'function') {
                        const result = await window.paymentApiInstance.cancelSubscription();
                        return { success: true, data: result };
                    }
                    return { success: false, reason: 'payment_api_not_available' };
                })();
                """

        case .openPaymentSheet(let payload):
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                return "({ success: false, reason: 'invalid_payload' });"
            }
            let safeJson = jsonString.jsEscaped
            return """
                (function() {
                    const payload = JSON.parse('\(safeJson)');
                    if (window.webkit && window.webkit.messageHandlers.paymentResponse) {
                        window.webkit.messageHandlers.paymentResponse.postMessage(payload);
                        return { success: true };
                    }
                    return { success: false, reason: 'message_handler_not_available' };
                })();
                """

        case .readTheme:
            return """
                (function() {
                    const theme = localStorage.getItem('theme');
                    return { success: true, theme: theme };
                })();
                """

        case .updateTheme(let theme):
            return """
                (function() {
                    localStorage.setItem('theme', '\(theme)');
                    return { success: true };
                })();
                """

        case .setupThemeListener:
            return JSBridgeManager.shared.loadScript(.themeChangeListener) ?? ""

        case .checkElementExists(let selector):
            let safeSelector = selector.jsEscaped
            return """
                (function() {
                    const element = document.querySelector('\(safeSelector)');
                    return { success: true, exists: element !== null };
                })();
                """

        case .simulateGarbageCollection:
            return "if (window.gc) { window.gc(); }"

        case .clearHistory:
            return """
                (function() {
                    history.pushState({}, '', window.location.href);
                    history.pushState({}, '', window.location.href);
                    history.go(-2);
                })();
                """

        case .initialSetup:
            return JSBridgeManager.shared.loadScript(.initialSetup) ?? ""

        case .setupMessageHandlers:
            return JSBridgeManager.shared.loadScript(.messageSubmissionListener) ?? ""

        case .setupPromotionHandler:
            return JSBridgeManager.shared.loadScript(.promotionButtonHandler) ?? ""

        case .setupVoiceEntry:
            return JSBridgeManager.shared.loadScript(.voiceEntrySetup) ?? ""
        }
    }

    /// User-friendly description for logging
    var description: String {
        switch self {
        case .insertPrompt(let text, let editorType):
            return "Insert prompt (\(editorType.rawValue)): \(text.prefix(50))..."
        case .getSubscriptions:
            return "Get subscriptions"
        case .restorePurchases:
            return "Restore purchases"
        case .cancelSubscription:
            return "Cancel subscription"
        case .openPaymentSheet:
            return "Open payment sheet"
        case .readTheme:
            return "Read theme"
        case .updateTheme(let theme):
            return "Update theme: \(theme)"
        case .setupThemeListener:
            return "Setup theme listener"
        case .checkElementExists(let selector):
            return "Check element exists: \(selector)"
        case .simulateGarbageCollection:
            return "Simulate garbage collection"
        case .clearHistory:
            return "Clear history"
        case .initialSetup:
            return "Initial setup"
        case .setupMessageHandlers:
            return "Setup message handlers"
        case .setupPromotionHandler:
            return "Setup promotion handler"
        case .setupVoiceEntry:
            return "Setup voice entry"
        }
    }

    /// Whether this command should be retried on failure
    var isRetryable: Bool {
        switch self {
        case .insertPrompt, .getSubscriptions, .restorePurchases:
            return true
        case .simulateGarbageCollection, .clearHistory:
            return false
        default:
            return false
        }
    }
}

import Foundation
import WebKit

/// Type-safe JavaScript commands that can be executed in the WebView
enum JSCommand {
    // MARK: - Prompt Operations
    case insertPrompt(text: String, editorType: EditorType)
    case clearPrompt
    
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
    case hideYourPlan
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
                
                if (window.LumoUtils && window.LumoUtils.applyLayoutStabilization) {
                    window.LumoUtils.applyLayoutStabilization();
                }
                
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
                
                editor.textContent = prompt;
                ['input', 'change'].forEach(eventType => {
                    editor.dispatchEvent(new Event(eventType, { bubbles: true }));
                });
                
                if (window.LumoUtils && window.LumoUtils.restoreLayout) {
                    window.LumoUtils.restoreLayout();
                }
                
                return { success: true, action: 'text_inserted' };
            })();
            """
            
        case .clearPrompt:
            return """
            (function() {
                const editor = document.querySelector('.tiptap.ProseMirror.composer') || 
                              document.querySelector('.composer') ||
                              document.querySelector('textarea.composer-textarea');
                if (editor) {
                    editor.textContent = '';
                    editor.dispatchEvent(new Event('input', { bubbles: true }));
                    return { success: true };
                }
                return { success: false, reason: 'editor_not_found' };
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
                  let jsonString = String(data: jsonData, encoding: .utf8) else {
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
            
        case .hideYourPlan:
            return JSBridgeManager.shared.loadScript(.hideYourPlan) ?? ""
            
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
        case .clearPrompt:
            return "Clear prompt"
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
        case .hideYourPlan:
            return "Hide your plan"
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
        case .insertPrompt, .clearPrompt, .getSubscriptions, .restorePurchases:
            return true
        case .simulateGarbageCollection, .clearHistory:
            return false
        default:
            return false
        }
    }
}

// MARK: - String Extension for JS Escaping
private extension String {
    /// Properly escape string for JavaScript injection
    var jsEscaped: String {
        return self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028") // Line separator
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029") // Paragraph separator
    }
}


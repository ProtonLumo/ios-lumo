import Foundation
import WebKit

enum JSBridgeScript: String, CaseIterable {
    case utilities = "utilities"
    
    case pageUtilities = "page-utilities"
    case initialSetup = "initial-setup"
    case commonSetup = "common-setup"
    case voiceEntrySetup = "voice-entry-setup"
    case promotionButtonHandler = "promotion-button-handler"
    case managePlanHandler = "manage-plan-handler"
    case hideUpgradeLink = "hide-upgrade-link"  // Handles both #your-plan and upgrade links
    case upgradeLinkClassifier = "upgrade-link-classifier"
    case messageSubmissionListener = "message-submission-listener"
    case externalLinkHandler = "external-link-handler"
    
    case paymentApi = "payment-api"
    
    // Theme management scripts
    case themeChangeListener = "theme-change-listener"
    case themeReader = "theme-reader"
    
    var filename: String {
        return "\(self.rawValue).js"
    }
    
    var requiresParameters: Bool {
        switch self {
        case .paymentApi:
            return true
        default:
            return false
        }
    }
}


class JSBridgeManager {
    static let shared = JSBridgeManager()
    
    private init() {}
    
    // MARK: - Public API
    
    func loadScript(_ script: JSBridgeScript) -> String? {
        let filename = script.filename
        return loadScriptFile(filename)
    }
    
    func createUserScript(_ script: JSBridgeScript, 
                         injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
                         forMainFrameOnly: Bool = true) -> WKUserScript? {
        guard let source = loadScript(script) else {
            Logger.shared.log("❌ Failed to load script: \(script.rawValue)")
            return nil
        }
        
        return WKUserScript(
            source: source,
            injectionTime: injectionTime,
            forMainFrameOnly: forMainFrameOnly
        )
    }
    
    func createParameterizedScript(_ script: JSBridgeScript, 
                                  parameters: [String: String],
                                  injectionTime: WKUserScriptInjectionTime = .atDocumentEnd,
                                  forMainFrameOnly: Bool = true) -> WKUserScript? {
        guard script.requiresParameters else {
            Logger.shared.log("❌ Script \(script.rawValue) is not a parameterized script")
            return nil
        }
        
        guard let scriptContent = loadScript(script) else {
            Logger.shared.log("❌ Failed to load script: \(script.rawValue)")
            return nil
        }
        
        let source = substituteParameters(in: scriptContent, parameters: parameters)
        
        return WKUserScript(
            source: source,
            injectionTime: injectionTime,
            forMainFrameOnly: forMainFrameOnly
        )
    }
    
    func evaluateScript(_ script: JSBridgeScript, 
                       in webView: WKWebView,
                       completion: ((Any?, Error?) -> Void)? = nil) {
        guard let source = loadScript(script) else {
            Logger.shared.log("❌ Failed to load script for evaluation: \(script.rawValue)")
            completion?(nil, NSError(domain: "JSBridgeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Script not found"]))
            return
        }
        
        webView.evaluateJavaScript(source, completionHandler: completion)
    }
    
    func evaluateParameterizedScript(_ script: JSBridgeScript,
                                   parameters: [String: String],
                                   in webView: WKWebView,
                                   completion: ((Any?, Error?) -> Void)? = nil) {
        guard script.requiresParameters else {
            Logger.shared.log("❌ Script \(script.rawValue) is not a parameterized script")
            completion?(nil, NSError(domain: "JSBridgeManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Script is not a parameterized script"]))
            return
        }
        
        guard let scriptContent = loadScript(script) else {
            Logger.shared.log("❌ Failed to load script for evaluation: \(script.rawValue)")
            completion?(nil, NSError(domain: "JSBridgeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Script not found"]))
            return
        }
        
        let source = substituteParameters(in: scriptContent, parameters: parameters)
        webView.evaluateJavaScript(source, completionHandler: completion)
    }
    
    // MARK: - Convenience Methods
    func createPaymentApiScript(operation: String,
                               data: String? = nil,
                               injectionTime: WKUserScriptInjectionTime = .atDocumentEnd) -> WKUserScript? {
        var parameters = ["OPERATION": operation]
        parameters["DATA"] = data ?? ""
        
        return createParameterizedScript(.paymentApi,
                                       parameters: parameters,
                                       injectionTime: injectionTime)
    }
    
    func evaluatePaymentApi(operation: String,
                          data: String? = nil,
                          in webView: WKWebView,
                          completion: ((Any?, Error?) -> Void)? = nil) {
        var parameters = ["OPERATION": operation]
        parameters["DATA"] = data ?? ""
        
        evaluateParameterizedScript(.paymentApi,
                                  parameters: parameters,
                                  in: webView,
                                  completion: completion)
    }
    
    func setupThemeChangeListener(in webView: WKWebView,
                                completion: ((Any?, Error?) -> Void)? = nil) {
        evaluateScript(.themeChangeListener, in: webView, completion: completion)
    }
    
    func readStoredTheme(in webView: WKWebView, completion: ((Any?, Error?) -> Void)? = nil) {
        evaluateScript(.themeReader, in: webView, completion: completion)
    }
    
    // MARK: - Private Methods
    private func loadScriptFile(_ filename: String) -> String? {
        let fileNameWithoutExtension: String
        let fileExtension: String?
        
        if filename.contains(".") {
            let components = filename.components(separatedBy: ".")
            fileNameWithoutExtension = components[0]
            fileExtension = components.count > 1 ? components[1] : nil
        } else {
            fileNameWithoutExtension = filename
            fileExtension = nil
        }
        
        if let bundlePath = Bundle.main.path(forResource: fileNameWithoutExtension, ofType: fileExtension),
           let content = try? String(contentsOfFile: bundlePath, encoding: .utf8) {
            Logger.shared.log("✅ Loaded JavaScript file from bundle root: \(filename)")
            return content
        }
        
        Logger.shared.log("❌ Failed to load JavaScript file: \(filename)")
        return nil
    }
    
    private func substituteParameters(in template: String, parameters: [String: String]) -> String {
        var result = template
        
        for (key, value) in parameters {
            let placeholder = "{{\(key)}}"
            result = result.replacingOccurrences(of: placeholder, with: value)
        }
        
        return result
    }
} 

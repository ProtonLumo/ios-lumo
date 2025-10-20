import SwiftUI
@preconcurrency import WebKit
import os.log
import Darwin


// Note: WKProcessPool was deprecated in iOS 15.0 - the system now manages process pools automatically

class PaymentBridgeCallbackHandler: NSObject, WKScriptMessageHandler {
    static var shared = PaymentBridgeCallbackHandler()
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let txId = messageBody["txId"] as? String,
              let resultString = messageBody["result"] as? String else {
            Logger.shared.log("Error: Invalid payment bridge callback message format")
            return
        }
        
        Logger.shared.log("Payment bridge callback received for transaction: \(txId)")
        PaymentBridge.shared.processJavascriptResult(resultString, transactionId: txId)
    }
}

class ThemeMessageHandler: NSObject, WKScriptMessageHandler {
    static let shared = ThemeMessageHandler()
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = message.name
        
        switch messageName {
        case "themeChanged":
            handleThemeChanged(message)
        case "themeRead":
            handleThemeRead(message)
        default:
            Logger.shared.log("⚠️ Unknown theme message: \(messageName)")
        }
    }
    
    private func handleThemeChanged(_ message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let theme = messageBody["theme"] as? String else {
            Logger.shared.log("❌ Invalid theme change message format")
            return
        }
        
        ThemeManager.shared.handleThemeChangeFromWeb(theme)
    }
    
    private func handleThemeRead(_ message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any] else {
            Logger.shared.log("❌ Invalid theme read message format")
            return
        }
        
        let success = messageBody["success"] as? Bool ?? false
        
        if success {
            let mode = messageBody["mode"] as? Int ?? 2 // default to light (web: 0=system, 1=dark, 2=light)
            let key = messageBody["key"] as? String ?? "unknown"
            
            // Stored theme found - use it (allows web override of system)
            Logger.shared.log("✅ Theme read from localStorage: mode=\(mode), key=\(key)")
            
            // Convert web mode value to native theme and mode
            // Web format: mode is the only value that matters (0=system, 1=dark, 2=light)
            let lumoTheme: LumoTheme
            let lumoMode: LumoThemeMode
            
            switch mode {
                case 0:
                    // Mode 0 = System theme
                    lumoTheme = .system
                    // Use ThemeManager's cached system appearance
                    lumoMode = ThemeManager.shared.getSystemThemeMode()
                case 1:
                    // Mode 1 = Explicit Dark theme
                    lumoTheme = .dark
                    lumoMode = .dark
                case 2:
                    // Mode 2 = Explicit Light theme
                    lumoTheme = .light
                    lumoMode = .light
                default:
                    // Fallback to system
                    lumoTheme = .system
                    lumoMode = ThemeManager.shared.getSystemThemeMode()
            }
            
            ThemeManager.shared.setStoredTheme(lumoTheme, mode: lumoMode)
        
        } else {
            let reason = messageBody["reason"] as? String ?? "Unknown error"
            Logger.shared.log("⚠️ Could not read stored theme: \(reason)")
            ThemeManager.shared.setDefaultSystemTheme()
        }
    }
}

// MARK: - WebView Component
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isReady: Bool
    @ObservedObject var jsCoordinator: WebViewCoordinator
    @Binding var action: WebViewAction?
    @Binding var canGoBack: Bool
    @Binding var currentURL: URL?
    @Binding var webViewStore: WKWebView?
    @Binding var networkError: Bool
    @Binding var processTerminated: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
            
            // Add observer for back navigation to lumo.proton.me
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ImportantDomainNavigation"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self else { return }
                
                if let waitForUI = notification.userInfo?["waitForUI"] as? Bool,
                   waitForUI == true {
                    
                    Logger.shared.log("Received back navigation to lumo.proton.me with waitForUI flag")
                    
                    // Ensure isReady is set to false for the transition
                    self.parent.isReady = false
                }
            }
            
            // Add keyboard observers to disable scrolling when keyboard appears
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleKeyboardWillShow(notification)
            }
            
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleKeyboardWillHide(notification)
            }
        }
        
        deinit {
            if let webView = parent.webViewStore {
                webView.scrollView.delegate = nil
            }
            
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        
        // MARK: - UIScrollViewDelegate
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return nil
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            if scrollView.zoomScale != 1.0 {
                scrollView.zoomScale = 1.0
            }
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scrollView.zoomScale != 1.0 {
                scrollView.setZoomScale(1.0, animated: false)
            }
        }
        
        // MARK: - Keyboard Handling
        
        private func handleKeyboardWillShow(_ notification: Notification) {
            Logger.shared.log("Keyboard will show - disabling WebView scrolling")
            if let webView = parent.webViewStore {
                webView.scrollView.isScrollEnabled = false
            }
        }
        
        private func handleKeyboardWillHide(_ notification: Notification) {
            Logger.shared.log("Keyboard will hide - re-enabling WebView scrolling")
            if let webView = parent.webViewStore {
                webView.scrollView.isScrollEnabled = true
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            // Handle links that open in new windows/tabs (target="_blank")
            // Note: Most external links are already intercepted by JavaScript (external-link-handler.js)
            // This is a fallback for edge cases where JS doesn't run or is bypassed
            if navigationAction.targetFrame == nil {
                Logger.shared.log("Target blank link detected: \(url.absoluteString)")
                
                // Check if it should open externally (fallback check)
                if shouldOpenInExternalBrowser(url: url) {
                    Logger.shared.log("Opening target blank URL in Safari: \(url.absoluteString)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
                
                // Internal target blank - load in current webview instead of creating popup
                webView.load(URLRequest(url: url))
                decisionHandler(.cancel)
                return
            }
            
            // Special case handling for about: URLs
            if url.absoluteString.starts(with: "about:") {
                Logger.shared.log("Allowing about: URL navigation: \(url.absoluteString)")
                decisionHandler(.allow)
                return
            }
            
            let urlString = url.absoluteString
            let currentUrlString = webView.url?.absoluteString ?? ""

            let isCrossDomainTransition = self.parent.isCrossDomainTransition(
                from: currentUrlString,
                to: urlString
            )

            // If we're navigating between domains, show loader IMMEDIATELY before navigation starts
            if isCrossDomainTransition {
                DispatchQueue.main.async {
                    self.parent.isReady = false
                    
                    // Post notification for domain transition to ensure loader shows
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ImportantDomainNavigation"),
                        object: nil,
                        userInfo: ["url": urlString, "isCrossDomain": true]
                    )
                    
                 
                }
            } else if urlString.contains(Config.ACCOUNT_BASE_URL) && currentUrlString.contains(Config.ACCOUNT_BASE_URL) {
                Logger.shared.log("Internal account navigation detected: \(currentUrlString) -> \(urlString) - NOT showing loader")
                DispatchQueue.main.async {
                    self.parent.isReady = true
                }
            }
            
            if url.absoluteString.contains("signup") {
                Logger.shared.log("✅ Signup URL detected!")
                
                if !url.absoluteString.contains("?plan=") && !url.absoluteString.contains("&plan=") {
                    Logger.shared.log("📝 Intercepted signup URL (no plan param): \(url.absoluteString)")
                    
                    let modifiedURLString = url.absoluteString.addingQueryParameter("plan", value: "free")
                    
                    Logger.shared.log("🔄 Redirecting to: \(modifiedURLString)")
                    
                    if let modifiedURL = URL(string: modifiedURLString) {
                        webView.load(URLRequest(url: modifiedURL))
                        decisionHandler(.cancel)
                        return
                    } else {
                        Logger.shared.log("❌ Failed to create modified URL")
                    }
                }
            }
            
            // IMPORTANT: We need to preserve proper history for account pages
            // Log navigation action type for debugging
            let actionType: String
            switch navigationAction.navigationType {
            case .linkActivated: actionType = "linkActivated"
            case .formSubmitted: actionType = "formSubmitted"
            case .backForward: actionType = "backForward"
            case .reload: actionType = "reload"
            case .formResubmitted: actionType = "formResubmitted"
            case .other: actionType = "other"
            @unknown default: actionType = "unknown"
            }
            
            Logger.shared.log("Navigation action: \(actionType) to URL: \(url.absoluteString)")
            
            // Always update the currentURL, regardless of page type
            DispatchQueue.main.async {
                self.parent.currentURL = url
                Logger.shared.log("Updated currentURL to: \(url.absoluteString)")
            }
            
            // Final fallback check: if JavaScript interception failed and this should open externally
            // This is a safety net - should rarely be hit since JS handles most cases
            if shouldOpenInExternalBrowser(url: url) {
                Logger.shared.log("Fallback: Opening external URL in Safari: \(url.absoluteString)")
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        // Helper function to determine if a URL should open in external browser
        private func shouldOpenInExternalBrowser(url: URL) -> Bool {
            let urlString = url.absoluteString
            
            if urlString.starts(with: "about:") {
                return false
            }
             
            if urlString.starts(with: "data:") {
                return false
            }
            
            if urlString.starts(with: "blob:") {
                return false
            }
            
            if urlString.contains("proton.me/support") {
                return true
            }
            
            if urlString.contains("proton.me/docs") {
                return true
            }
            
            if urlString.contains("proton.me/legal") || 
               urlString.contains("proton.me/terms") || 
               urlString.contains("proton.me/privacy") {
                return true
            }
            
            let allowedDomains = [
                Config.LUMO_BASE_URL,
                Config.LUMO_API_BASE_URL,
                Config.ACCOUNT_BASE_URL,
                Config.ACCOUNT_API_BASE_URL,
                "js.chargebee.com",
                "captcha.proton."
            ]
            
            for domain in allowedDomains {
                if urlString.contains(domain) {
                    Logger.shared.log("URL contains allowed domain '\(domain)': \(urlString)")
                    return false
                }
            }
            
            Logger.shared.log("URL does not contain any allowed domains, opening externally: \(urlString)")
            return true
        }
        
        // Called when navigation fails
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Logger.shared.log("WebView failed to load: \(error)")
            
            DispatchQueue.main.async {
                self.parent.isReady = true
                self.parent.canGoBack = webView.canGoBack
                self.parent.currentURL = webView.url
                
                // Check for network connectivity errors
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && 
                   (nsError.code == NSURLErrorNotConnectedToInternet || 
                    nsError.code == NSURLErrorNetworkConnectionLost ||
                    nsError.code == NSURLErrorCannotConnectToHost) {
                    Logger.shared.log("Network connectivity error detected")
                    self.parent.networkError = true
                }
            }
            
            // Attempt to recover from navigation errors
            if (error as NSError).code == NSURLErrorCancelled {
                // This is often caused by rapid navigation attempts - usually safe to ignore
                Logger.shared.log("Navigation was cancelled - likely a redirect or user action")
                return
            }
            
            // For other errors, try to go back to a safe state
            if webView.canGoBack {
                Logger.shared.log("Attempting to recover by going back to previous page")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    webView.goBack()
                }
            } else if webView.url == nil || webView.url?.absoluteString.isEmpty == true {
                // If we're in a bad state with no URL, reload the main page
                Logger.shared.log("Reloading main page to recover from error")
                webView.loadLumoBase()
            }
        }

        // Handle popup windows (window.open, target="_blank")
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Check if this URL should open externally
            if let url = navigationAction.request.url {
                Logger.shared.log("🪟 Popup window requested for: \(url.absoluteString)")
                
                if shouldOpenInExternalBrowser(url: url) {
                    Logger.shared.log("Opening popup URL in Safari: \(url.absoluteString)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    // Load in current webview instead of creating popup
                    Logger.shared.log("Loading in current webview instead of popup: \(url.absoluteString)")
                    webView.load(navigationAction.request)
                }
            }
            
            // Return nil to prevent popup creation
            return nil
        }
        
        // Called when navigation finishes successfully
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let urlString = webView.url?.absoluteString ?? "unknown"
            Logger.shared.log("WebView finished navigating to: \(urlString)")
            
            // Immediately update URL to ensure proper state tracking
            DispatchQueue.main.async {
                self.parent.currentURL = webView.url
            }
            
            // Read stored theme from localStorage now that the page is loaded
            // Add a delay to ensure web app has fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ThemeManager.shared.readStoredTheme()
            }
            
            // Fallback: Check if we landed on a signup page without plan parameter
            if urlString.hasPrefix("\(Config.ACCOUNT_BASE_URL)/lumo/signup") &&
               !urlString.contains("?plan=") && !urlString.contains("&plan=") {
                Logger.shared.log("🔄 FALLBACK: Detected signup page without plan parameter, redirecting...")
                
                let modifiedURLString = urlString.addingQueryParameter("plan", value: "free")
                
                Logger.shared.log("🔄 FALLBACK: Redirecting to: \(modifiedURLString)")
                
                if let modifiedURL = URL(string: modifiedURLString) {
                    DispatchQueue.main.async {
                        webView.load(URLRequest(url: modifiedURL))
                    }
                    return
                }
            }
            
            webView.scrollView.zoomScale = 1.0
            
            DispatchQueue.main.async {
                self.parent.disableAllZoomGestures(in: webView)
            }
            
            webView.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            
            webView.scrollView.refreshControl?.endRefreshing()
            
            if urlString.contains(Config.ACCOUNT_BASE_URL) {
                Logger.shared.log("On account.proton.me domain - keeping loader visible through auth flow")
                
                JSBridgeManager.shared.evaluateScript(.initialSetup, in: webView) { _, error in
                    if let error = error {
                        Logger.shared.log("Error applying initial setup: \(error)")
                    } else {
                        Logger.shared.log("Applied initial setup to account page")
                    }
                }
                
                JSBridgeManager.shared.evaluateScript(.hideYourPlan, in: webView) { (result, error) in
                    if let error = error {
                        Logger.shared.log("Error injecting hide #your-plan script: \(error)")
                    } else {
                        Logger.shared.log("Successfully injected script to hide #your-plan section")
                    }
                }
            
            }
            
            else if urlString.contains(Config.LUMO_BASE_URL) {
                Logger.shared.log("On lumo.proton.me domain - checking for UI readiness")
                
                JSBridgeManager.shared.evaluateScript(.pageUtilities, in: webView) { (result, error) in
                    if let error = error {
                        Logger.shared.log("Error applying viewport fix or checking for element: \(error)")
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            Logger.shared.log("Setting isReady=true after error")
                            self.parent.isReady = true
                        }
                        return
                    }
                    
                    if let resultDict = result as? [String: Any],
                       let elementFound = resultDict["elementFound"] as? Bool {
                        
                        if elementFound {
                            Logger.shared.log("✅ Target element .lumo-input-container found - UI is ready")
                            DispatchQueue.main.async {
                                self.parent.isReady = true
                            }
                        } else {
                            Logger.shared.log("Target element .lumo-input-container not found yet - will check again")
                            self.checkForElementWithRetry(webView: webView)
                        }
                    } else {
                        Logger.shared.log("Unexpected result format from element check script")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.parent.isReady = true
                        }
                    }
                }
                
                // Inject deferred scripts for lumo.proton.me as backup
                self.injectDeferredScriptsBackup(webView: webView)
            }
            else {
                Logger.shared.log("On other domain: \(urlString) - applying standard loading behavior")
                JSBridgeManager.shared.evaluateScript(.initialSetup, in: webView) { _, error in
                    if let error = error {
                        Logger.shared.log("Error applying initial setup: \(error)")
                    } else {
                        Logger.shared.log("Applied initial setup to other domain")
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if webView.url?.absoluteString.contains(urlString) == true {
                        Logger.shared.log("Setting isReady=true after delay on other domain")
                        self.parent.isReady = true
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if !self.parent.isReady {
                    Logger.shared.log("⚠️ Global safety timeout reached - forcing isReady=true")
                    self.parent.isReady = true
                }
            }
            
            JSBridgeManager.shared.evaluateScript(.commonSetup, in: webView) { (result, error) in
                if let error = error {
                    Logger.shared.log("Error injecting common JavaScript: \(error)")
                } else {
                    Logger.shared.log("Successfully injected common JavaScript")
                }
            }
            
            JSBridgeManager.shared.evaluateScript(.voiceEntrySetup, in: webView) { (result, error) in
                if let error = error {
                    Logger.shared.log("Error injecting voice entry setup: \(error)")
                } else {
                    Logger.shared.log("Successfully injected voice entry setup")
                }
            }
        }

        private func injectDeferredScriptsBackup(webView: WKWebView) {
            let deferredScripts: [JSBridgeScript] = [
                .promotionButtonHandler,
                .managePlanHandler,
                .upgradeLinkClassifier,
                .messageSubmissionListener
            ]
            
            for script in deferredScripts {
                JSBridgeManager.shared.evaluateScript(script, in: webView) { result, error in
                    if let error = error {
                        Logger.shared.log("Error injecting deferred script \(script.rawValue): \(error)")
                    }
                }
            }
            
            // Setup theme change listener
            ThemeManager.shared.setupThemeChangeListener()
        }

        private func checkForElementWithRetry(webView: WKWebView) {
            struct RetryState {
                static var attempts = 0
                static let maxAttempts = 10
            }
            
            RetryState.attempts = 0
            
            func checkForElement() {
                RetryState.attempts += 1
                
                if RetryState.attempts > RetryState.maxAttempts {
                    Logger.shared.log("Exceeded max attempts (\(RetryState.maxAttempts)) checking for element - setting isReady=true")
                    self.parent.isReady = true
                    return
                }
                
                JSBridgeManager.shared.evaluateScript(.pageUtilities, in: webView) { (result, error) in
                    if let error = error {
                        Logger.shared.log("Error checking for element: \(error)")
                        self.parent.isReady = true
                        return
                    }
                    
                    if let elementFound = result as? Bool, elementFound {
                        Logger.shared.log("Element found on attempt \(RetryState.attempts)")
                        DispatchQueue.main.async {
                            self.parent.isReady = true
                        }
                    } else {
                        let delay = Double(RetryState.attempts) * 0.2 // Increase delay with each attempt
                        Logger.shared.log("Element not found on attempt \(RetryState.attempts), checking again in \(delay)s")
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            checkForElement()
                        }
                    }
                }
            }
            
            checkForElement()
        }

        // Called when navigation starts
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            let urlString = webView.url?.absoluteString ?? "unknown"
            Logger.shared.log("WebView started loading: \(urlString)")
            
            let previousUrl = self.parent.currentURL?.absoluteString ?? ""
            let isFromAccount = previousUrl.contains(Config.ACCOUNT_BASE_URL)
            let isToAccount = urlString.contains(Config.ACCOUNT_BASE_URL)
            let isToLumo = urlString.contains(Config.LUMO_BASE_URL)
            
            if isFromAccount && isToAccount {
                Logger.shared.log("Account-to-account navigation detected - skipping loading screen: \(previousUrl) -> \(urlString)")
                return
            }
            
            DispatchQueue.main.async {
                self.parent.isReady = false
                
                if isFromAccount && isToLumo {
                    Logger.shared.log("⚠️ CRITICAL TRANSITION: account→lumo detected - ensuring loading view is visible")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ImportantDomainNavigation"),
                        object: nil,
                        userInfo: [
                            "url": urlString, 
                            "isCrossDomain": true,
                            "isAccountToLumo": true
                        ]
                    )
                } else {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ImportantDomainNavigation"),
                        object: nil,
                        userInfo: ["url": urlString, "isCrossDomain": true]
                    )
                }
                
                Logger.shared.log("Setting isReady=false for navigation to \(urlString)")
                
                // Reduced timeout from 10s to 7s for better user experience
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                    if !self.parent.isReady {
                        Logger.shared.log("⚠️ Navigation safety timeout reached for \(urlString)")
                        if !urlString.contains("account.proton.me") {
                            webView.loadLumoBase()
                        } else {
                            Logger.shared.log("Staying on account page after timeout to preserve user flow")
                        }
                        self.parent.isReady = true
                    }
                }
            }
        }
        
        // Add handler for navigation failures
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Logger.shared.log("WebView failed provisional navigation with error: \(error)")
            
            DispatchQueue.main.async {
                self.parent.isReady = true
                
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && 
                   (nsError.code == NSURLErrorNotConnectedToInternet || 
                    nsError.code == NSURLErrorNetworkConnectionLost ||
                    nsError.code == NSURLErrorCannotConnectToHost ||
                    nsError.code == NSURLErrorTimedOut) {
                    Logger.shared.log("Network connectivity error detected during provisional navigation")
                    self.parent.networkError = true
                }
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            Logger.shared.log("⚠️ WebContent process terminated - attempting recovery")
            
            DispatchQueue.main.async {
                self.parent.isReady = true
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("WebContentProcessDidTerminate"),
                    object: nil
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Logger.shared.log("Attempting to reload after WebKit process termination")
                    if let url = webView.url {
                        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                        webView.load(request)
                    } else {
                        webView.loadLumoBase()
                    }
                }
            }
        }

        // Add refresh control handler
        @objc func handleRefreshControl(_ refreshControl: UIRefreshControl) {
            Logger.shared.log("Pull-to-refresh triggered")
            
            if let webView = refreshControl.superview?.superview as? WKWebView {
                if let url = webView.url {
                    Logger.shared.log("Refreshing page: \(url.absoluteString)")
                    webView.reload()
                } else {
                    Logger.shared.log("No URL to refresh, loading home page")
                    if let mainURL = URL(string: "https://lumo.proton.me") {
                        webView.load(URLRequest(url: mainURL))
                    }
                }
            }
            
            // End refreshing after a short delay for better user feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        if #available(iOS 15.0, *) {
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.preferredContentMode = .mobile
            configuration.defaultWebpagePreferences = pagePrefs
        }

        configuration.allowsInlineMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.userContentController = WKUserContentController()
        
        let dataStore = WKWebsiteDataStore.default()
        
        let cacheDataTypes: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeOfflineWebApplicationCache
        ]
        
        DispatchQueue.main.async {
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            dataStore.removeData(ofTypes: cacheDataTypes, modifiedSince: sevenDaysAgo) { 
                Logger.shared.log("Cleaned up cache data older than 7 days")
            }
        }
        
        configuration.websiteDataStore = dataStore
        // Note: No need to set processPool - iOS 15.0+ manages this automatically
        configuration.limitsNavigationsToAppBoundDomains = true
        
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = false
        preferences.isTextInteractionEnabled = true
        
        if #available(iOS 15.0, *) {
            preferences.isElementFullscreenEnabled = false
            preferences.isFraudulentWebsiteWarningEnabled = false
            configuration.allowsAirPlayForMediaPlayback = false
            
            if #available(iOS 16.0, *) {
                configuration.defaultWebpagePreferences.preferredContentMode = .mobile
            }
        }
        
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = WKWebView.generateCustomUserAgent()
        webView.isInspectable = true
        let paymentHandler = PaymentHandler(webView: webView) { action in
            switch action.type {
            case .createSubscription:
                self.action = .postSubscription(payload: action.payload)
            case .createToken:
                self.action = .postToken(payload: action.payload)
            case .getPlans:
                self.action = .getPlans
            case .getSubscriptions:
                self.action = .getSubscriptions
            }
        }
        configuration.userContentController.add(paymentHandler, name: "showPayment")
        
        PurchaseManager.shared.setup(webView: webView)
        class UnifiedMessageHandler: NSObject, WKScriptMessageHandler {
            let parent: WebView
            private var lastSubmitTime: Date?
            private let submitDebounceInterval: TimeInterval = 0.5
            
            init(_ parent: WebView) {
                self.parent = parent
            }
            
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                let messageName = message.name
                Logger.shared.log("📨 Received message: \(messageName)")
                
                DispatchQueue.main.async {
                    switch messageName {
                    case "navigationState":
                        self.handleNavigationState(message)
                    case "paymentResponse":
                        self.handlePaymentResponse(message)
                    case "submitButtonClicked":
                        self.handleSubmitButtonClicked()
                    case "elementFound":
                        self.handleElementFound(message)
                    case "insertPrompt":
                        self.handleInsertPrompt(message)
                    case "startVoiceEntry":
                        self.handleStartVoiceEntry()
                    case "promotionButtonClicked":
                        self.handlePromotionButtonClicked()
                    case "managePlanClicked":
                        self.handleManagePlanClicked()
                    case "getSubscriptionsResponseReceived":
                        self.handleGetSubscriptionsResponse(message)
                    case "openExternalURL":
                        self.handleOpenExternalURL(message)
                    default:
                        Logger.shared.log("⚠️ Unknown message: \(messageName)")
                    }
                }
            }
            
            private func handleNavigationState(_ message: WKScriptMessage) {
                guard let dict = message.body as? [String: Any] else { return }
                
                if let action = dict["action"] as? String, action == "forceBack" {
                    Logger.shared.log("Received forceBack action from JavaScript")
                    if let webView = self.parent.webViewStore, webView.canGoBack {
                        webView.goBack()
                    }
                    return
                }
                
                if let canGoBack = dict["canGoBack"] as? Bool {
                    let nativeCanGoBack = self.parent.webViewStore?.canGoBack ?? false
                    self.parent.canGoBack = nativeCanGoBack || canGoBack
                }
                
                if let urlString = dict["url"] as? String, let url = URL(string: urlString) {
                    self.parent.currentURL = url
                }
            }
            
            private func handlePaymentResponse(_ message: WKScriptMessage) {
                if let response = message.body as? [String: Any] {
                    NotificationCenter.default.post(
                        name: Notification.Name("PaymentResponseReceived"),
                        object: nil,
                        userInfo: ["response": response]
                    )
                }
            }
            
            private func handleSubmitButtonClicked() {
                let now = Date()
                if let lastTime = lastSubmitTime, 
                   now.timeIntervalSince(lastTime) < submitDebounceInterval {
                    return
                }
                lastSubmitTime = now
                
                NotificationCenter.default.post(name: NSNotification.Name("SubmitButtonClicked"), object: nil)
            }
            
            private func handleElementFound(_ message: WKScriptMessage) {
                self.parent.isReady = true
            }
            
            private func handleInsertPrompt(_ message: WKScriptMessage) {
                if let body = message.body as? [String: Any],
                   let prompt = body["prompt"] as? String {
                    // Use coordinator directly
                    Task {
                        await self.parent.jsCoordinator.insertPrompt(prompt, editorType: .tiptap)
                    }
                }
            }
            
            private func handleStartVoiceEntry() {
                NotificationCenter.default.post(name: Notification.Name("StartVoiceEntryNotification"), object: nil)
            }
            
            private func handleOpenExternalURL(_ message: WKScriptMessage) {
                if let body = message.body as? [String: Any],
                   let urlString = body["url"] as? String,
                   let url = URL(string: urlString) {
                    Logger.shared.log("Opening external URL from JS: \(urlString)")
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            
            private func handlePromotionButtonClicked() {
                NotificationCenter.default.post(name: Notification.Name("PromotionButtonClicked"), object: nil)
            }
            
            private func handleManagePlanClicked() {
                NotificationCenter.default.post(name: Notification.Name("ManagePlanClicked"), object: nil)
            }
            
            private func handleGetSubscriptionsResponse(_ message: WKScriptMessage) {
                if let messageBody = message.body as? [String: Any],
                   let response = messageBody["response"] as? [String: Any] {
                    NotificationCenter.default.post(
                        name: Notification.Name("getSubscriptionsResponseReceived"),
                        object: response
                    )
                }
            }
        }
        
        let unifiedHandler = UnifiedMessageHandler(self)
        let messageNames = ["navigationState", "paymentResponse", "submitButtonClicked", "elementFound", 
                           "insertPrompt", "startVoiceEntry", "promotionButtonClicked", "managePlanClicked", 
                           "getSubscriptionsResponseReceived", "openExternalURL"]
        
        for messageName in messageNames {
            configuration.userContentController.add(unifiedHandler, name: messageName)
        }

        configuration.userContentController.add(PaymentBridgeCallbackHandler.shared, name: "paymentBridgeCallback")
        
        // Add theme message handlers
        let themeHandler = ThemeMessageHandler.shared
        configuration.userContentController.add(themeHandler, name: "themeChanged")
        configuration.userContentController.add(themeHandler, name: "themeRead")

        if let utilitiesScript = JSBridgeManager.shared.createUserScript(.utilities, injectionTime: .atDocumentStart, forMainFrameOnly: true) {
            configuration.userContentController.addUserScript(utilitiesScript)
        }

        if let voiceEntryScript = JSBridgeManager.shared.createUserScript(.voiceEntrySetup, injectionTime: .atDocumentEnd, forMainFrameOnly: false) {
            configuration.userContentController.addUserScript(voiceEntryScript)
        }
        
        if let externalLinkScript = JSBridgeManager.shared.createUserScript(.externalLinkHandler, injectionTime: .atDocumentEnd, forMainFrameOnly: false) {
            configuration.userContentController.addUserScript(externalLinkScript)
        }

        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.zoomScale = 1.0
        webView.scrollView.bouncesZoom = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = false
        
        DispatchQueue.main.async {
            self.disableAllZoomGestures(in: webView)
            self.webViewStore = webView
            
        // Setup theme management
        ThemeManager.shared.setup(webView: webView)
        }
        
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        
        URLCache.shared.memoryCapacity = 20 * 1024 * 1024
        URLCache.shared.diskCapacity = 50 * 1024 * 1024
        
        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 30
        
        webView.load(request)
        
        // Ensure cookie operations happen on main thread
        DispatchQueue.main.async { [weak webView] in
            guard let webView = webView else { return }
            let dataStore = webView.configuration.websiteDataStore
            dataStore.httpCookieStore.getAllCookies { cookies in
                Logger.shared.log("Loaded \(cookies.count) cookies for session persistence")
                let authCookies = cookies.filter { cookie in
                    cookie.domain.contains("proton.me") || cookie.domain.contains("lumo")
                }
                Logger.shared.log("Found \(authCookies.count) authentication-related cookies")
            }
        }
        
        class FirstLoadObserver: NSObject {
            private var observation: NSKeyValueObservation?
            
            init(webView: WKWebView) {
                super.init()
                
                observation = webView.observe(\.isLoading, options: [.new]) { [weak self] webView, change in
                    if let isLoading = change.newValue, !isLoading {
                        JSBridgeManager.shared.evaluateScript(.initialSetup, in: webView) { _, _ in
                            self?.injectDeferredScripts(webView: webView)
                            self?.observation?.invalidate()
                            self?.observation = nil
                        }
                    }
                }
            }
            
            private func injectDeferredScripts(webView: WKWebView) {
                let deferredScripts: [JSBridgeScript] = [
                    .promotionButtonHandler,
                    .managePlanHandler,
                    .upgradeLinkClassifier,
                    .messageSubmissionListener
                ]
                
                for script in deferredScripts {
                    JSBridgeManager.shared.evaluateScript(script, in: webView) { _, error in
                        if let error = error {
                            Logger.shared.log("Error injecting deferred script \(script.rawValue): \(error)")
                        }
                    }
                }
                
                // Setup theme change listener
                ThemeManager.shared.setupThemeChangeListener()
            }
        }

        let _ = FirstLoadObserver(webView: webView)

        return webView
    }
    
    private func disableAllZoomGestures(in webView: WKWebView) {
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        
        let allGestureRecognizers = webView.scrollView.gestureRecognizers ?? []
        for gesture in allGestureRecognizers {
            if let pinchGesture = gesture as? UIPinchGestureRecognizer {
                pinchGesture.isEnabled = false
            }
            if let tapGesture = gesture as? UITapGestureRecognizer, tapGesture.numberOfTapsRequired == 2 {
                tapGesture.isEnabled = false
            }
        }
        
        func disableGesturesRecursively(in view: UIView) {
            for gesture in view.gestureRecognizers ?? [] {
                if let pinchGesture = gesture as? UIPinchGestureRecognizer {
                    pinchGesture.isEnabled = false
                }
                if let tapGesture = gesture as? UITapGestureRecognizer, tapGesture.numberOfTapsRequired == 2 {
                    tapGesture.isEnabled = false
                }
            }
            for subview in view.subviews {
                disableGesturesRecursively(in: subview)
            }
        }
        
        disableGesturesRecursively(in: webView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            webView.scrollView.minimumZoomScale = 1.0
            webView.scrollView.maximumZoomScale = 1.0
            webView.scrollView.zoomScale = 1.0
            webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        }
    }


    func updateUIView(_ webView: WKWebView, context: Context) {
        // Configure coordinator with WebView reference (if not already done)
        if !jsCoordinator.isReady && isReady {
            jsCoordinator.configure(with: webView)
        }
        
        if !isReady {
            return
        }
        
        DispatchQueue.main.async {
            if let url = webView.url {
                if url.absoluteString.contains(Config.ACCOUNT_BASE_URL) {
                    self.canGoBack = true
                } else if self.canGoBack != webView.canGoBack {
                    Logger.shared.log("Updating canGoBack state in updateUIView: \(webView.canGoBack)")
                    self.canGoBack = webView.canGoBack
                }
                
                if self.currentURL != webView.url {
                    self.currentURL = webView.url
                }
            }
        }
        
        if let currentAction = action {
            self.handleWebViewAction(webView: webView, action: currentAction)
        }
    }

    private func handleWebViewAction(webView: WKWebView, action: WebViewAction) {
        Logger.shared.log("WebView processing action: \(action)")
        
        switch action {
        case .postSubscription(let payload):
            executePaymentAction(operation: "createSubscription", payload: payload, webView: webView)
        case .postToken(let payload):
            executePaymentAction(operation: "createToken", payload: payload, webView: webView)
        case .getPlans:
            JSBridgeManager.shared.evaluatePaymentApi(operation: "getPlans", in: webView) { (result, error) in
                if let error = error {
                    Logger.shared.log("Error executing getPlans script: \(error)")
                } else if let resultData = result as? String, 
                          let jsonData = resultData.data(using: .utf8),
                          let jsonResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("getPlansResponseReceived"),
                        object: nil,
                        userInfo: ["response": jsonResult]
                    )
                }
            }
        case .getSubscriptions:
            JSBridgeManager.shared.evaluatePaymentApi(operation: "getSubscriptions", in: webView) { (result, error) in
                if let error = error {
                    Logger.shared.log("Error executing getSubscriptions script: \(error)")
                }
            }
        }
        
        self.resetAction()
    }
    
    private func executePaymentAction(operation: String, payload: [String: Any], webView: WKWebView) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                Logger.shared.log("Error: Could not convert \(operation) JSON data to String.")
                return
            }
            
            JSBridgeManager.shared.evaluatePaymentApi(operation: operation, data: jsonString, in: webView) { (result, error) in
                if let error = error {
                    Logger.shared.log("Error executing \(operation) script: \(error)")
                } else {
                    Logger.shared.log("\(operation) script executed successfully")
                }
            }
        } catch {
            Logger.shared.log("Error: Could not serialize \(operation) payload: \(error)")
        }
    }

    private func resetAction() {
        DispatchQueue.main.async {
            self.action = nil
        }
    }


    private func safeWebViewOperation(_ operation: (WKWebView) -> Void) {
        if let webView = webViewStore, webView.superview != nil {
            operation(webView)
        } else {
            Logger.shared.log("WebView reference is nil or WebView has been removed from view hierarchy")
        }
    }
    

}

extension WebView {

    func isCrossDomainTransition(from sourceURL: String, to destinationURL: String) -> Bool {
        let isSourceLumo = sourceURL.contains(Config.LUMO_BASE_URL)
        let isSourceAccount = sourceURL.contains(Config.ACCOUNT_BASE_URL)
        
        let isDestinationLumo = destinationURL.contains(Config.LUMO_BASE_URL)
        let isDestinationAccount = destinationURL.contains(Config.ACCOUNT_BASE_URL)
        
        return (isDestinationLumo && isSourceAccount) || 
               (isDestinationAccount && isSourceLumo)
    }
}


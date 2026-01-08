import Foundation
import WebKit

/// Utility to detect if iOS Lockdown Mode is enabled
/// Uses the official WKWebPagePreferences.isLockdownModeEnabled API (iOS 16.0+)
class LockdownModeDetector {
    static let shared = LockdownModeDetector()

    private init() {}

    func isLockdownModeEnabled(webView: WKWebView? = nil) -> Bool {
        if #available(iOS 16.0, *) {
            if let webView = webView {
                return webView.configuration.defaultWebpagePreferences.isLockdownModeEnabled
            } else {
                let preferences = WKWebpagePreferences()
                return preferences.isLockdownModeEnabled
            }
        } else {
            // Fallback for iOS < 16.0: Lockdown Mode was introduced in iOS 16
            return false
        }
    }
}

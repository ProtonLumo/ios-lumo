import Foundation
import UIKit
import WebKit

extension String {
    /// Adds a query parameter to a URL string
    /// - Parameters:
    ///   - parameter: The parameter name
    ///   - value: The parameter value
    /// - Returns: URL string with the parameter added
    func addingQueryParameter(_ parameter: String, value: String) -> String {
        if self.contains("?") {
            return self + "&\(parameter)=\(value)"
        } else {
            return self + "?\(parameter)=\(value)"
        }
    }
}

extension URL {
    /// Creates a URL for the main Lumo base URL
    static var lumoBase: URL? {
        URL(string: Config.LUMO_BASE_URL)
    }
}

extension URLRequest {
    /// Creates a URLRequest with cache-busting policy
    /// - Parameter url: The URL for the request
    /// - Returns: URLRequest configured to ignore cache
    static func cacheBusting(url: URL) -> URLRequest {
        URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
    }
}

extension WKWebView {
    /// Safely loads the main Lumo URL
    func loadLumoBase() {
        guard let url = URL.lumoBase else {
            Logger.shared.log("Failed to create Lumo base URL")
            return
        }
        load(URLRequest(url: url))
    }

    /// Safely loads the main Lumo URL with cache busting
    func loadLumoBaseWithCacheBusting() {
        guard let url = URL.lumoBase else {
            Logger.shared.log("Failed to create Lumo base URL")
            return
        }
        load(URLRequest.cacheBusting(url: url))
    }

    /// Generates a custom user agent string following Proton standard format
    /// Format: "Proton<product>/<product-version> (<os-name-and-version>; <platform-or-device>)"
    static func generateCustomUserAgent() -> String {
        // Get app version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        // Get OS name and version dynamically
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion

        // Get device information
        let deviceModel = UIDevice.current.model
        let deviceName = UIDevice.current.name

        // Clean up device name - use the user-friendly name if available, otherwise fall back to model
        let cleanDeviceName: String
        if !deviceName.isEmpty && deviceName != deviceModel {
            cleanDeviceName = deviceName
        } else {
            cleanDeviceName = deviceModel
        }

        return "ProtonLumo/\(appVersion) (\(osName)/\(osVersion); \(cleanDeviceName))"
    }
}

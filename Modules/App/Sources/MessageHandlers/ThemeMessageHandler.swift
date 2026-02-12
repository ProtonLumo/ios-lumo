import LumoCore
import WebKit

final class ThemeMessageHandler: NSObject, WKScriptMessageHandler, WKMessageHandlerRegistering {
    enum MessageName: String, CaseIterable {
        case themeChanged
        case themeRead
    }

    // MARK: - WKMessageHandlerRegistering

    func registerForAll(in configuration: WKWebViewConfiguration) {
        MessageName.allCases.forEach { message in
            configuration.userContentController.add(self, name: message.rawValue)
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = MessageName(rawValue: message.name)

        switch messageName {
        case .themeChanged:
            handleThemeChanged(message)
        case .themeRead:
            handleThemeRead(message)
        case .none:
            Logger.shared.log("⚠️ Unknown theme message: \(message.name)")
        }
    }

    // MARK: - Private

    private func handleThemeChanged(_ message: WKScriptMessage) {
        guard
            let messageBody = message.body as? [String: Any],
            let theme = messageBody["theme"] as? String
        else {
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
            let mode: WebUIInterfaceStyle = WebUIInterfaceStyle(rawValue: messageBody["mode"] as? Int, fallback: .light)
            let key = messageBody["key"] as? String ?? "unknown"

            // Stored theme found - use it (allows web override of system)
            Logger.shared.log("✅ Theme read from localStorage: mode=\(mode), key=\(key)")

            let lumoTheme: LumoTheme
            let lumoMode: LumoThemeMode

            switch mode {
            case .system:
                lumoTheme = .system
                // Use ThemeManager's cached system appearance
                lumoMode = ThemeManager.shared.getSystemThemeMode()
            case .dark:
                lumoTheme = .dark
                lumoMode = .dark
            case .light:
                lumoTheme = .light
                lumoMode = .light
            }

            ThemeManager.shared.setStoredTheme(lumoTheme, mode: lumoMode)
        } else {
            let reason = messageBody["reason"] as? String ?? "Unknown error"
            Logger.shared.log("⚠️ Could not read stored theme: \(reason)")
            ThemeManager.shared.setDefaultSystemTheme()
        }
    }
}

private enum WebUIInterfaceStyle: Int {
    case system = 0
    case dark = 1
    case light = 2

    init(rawValue: Int?, fallback: WebUIInterfaceStyle) {
        let interfaceStyle = rawValue.flatMap(WebUIInterfaceStyle.init)
        self = interfaceStyle ?? fallback
    }
}

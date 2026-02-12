import WebKit

class ThemeMessageHandler: NSObject, WKScriptMessageHandler {
    static let shared = ThemeMessageHandler()

    // MARK: - WKScriptMessageHandler

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
            let mode = messageBody["mode"] as? Int ?? 2  // default to light (web: 0=system, 1=dark, 2=light)
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

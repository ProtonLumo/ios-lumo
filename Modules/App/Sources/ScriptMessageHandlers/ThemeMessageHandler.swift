import LumoCore
import WebKit

final class ThemeMessageHandler: NSObject, WebScriptMessageHandler {
    private let themeStore: ThemeStore

    init(themeStore: ThemeStore) {
        self.themeStore = themeStore
    }

    // MARK: - WebScriptMessageHandler

    enum MessageName: String, CaseIterable {
        case themeChanged
        case themeRead
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch MessageName(rawValue: message.name) {
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
            let body = message.body as? [String: Any],
            let themeName = body["theme"] as? String
        else {
            Logger.shared.log("[THEME] ❌ themeChanged: invalid message format")
            return
        }

        guard let theme = WebColorScheme(name: themeName) else {
            Logger.shared.log("[THEME] ❌ themeChanged: unknown theme name '\(themeName)'")
            return
        }

        themeStore.apply(theme: theme)
    }

    private func handleThemeRead(_ message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            Logger.shared.log("[THEME] ❌ themeRead: invalid message format")
            return
        }

        guard body["success"] as? Bool == true else {
            Logger.shared.log("[THEME] ⚠️ themeRead: could not read localStorage – \(body["reason"] as? String ?? "unknown")")
            return
        }

        let mode = body["mode"] as? Int
        let theme = WebColorScheme(mode: mode)

        themeStore.apply(theme: theme)
    }
}

private extension WebColorScheme {
    /// Init from localStorage int value (themeRead): 0 = system, 1 = dark, 2 = light.
    init(mode: Int?) {
        switch mode {
        case 1: self = .dark
        case 2: self = .light
        default: self = .system
        }
    }

    /// Init from JS event string value (themeChanged). Case-insensitive.
    init?(name: String) {
        switch name.lowercased() {
        case "light": self = .light
        case "dark": self = .dark
        case "system": self = .system
        default: return nil
        }
    }
}

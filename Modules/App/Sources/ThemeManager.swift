import Foundation
import UIKit
import WebKit

// Theme constants for native app (converted from web app values)
enum LumoTheme: Int {
    case light = 0
    case dark = 1
    case system = 2
}

enum LumoThemeMode: Int {
    case light = 0
    case dark = 1
}

class ThemeManager: NSObject {
    static let shared = ThemeManager()

    private var webView: WKWebView?
    private(set) var currentTheme: LumoTheme = .system
    private(set) var currentMode: LumoThemeMode = .light

    // Cache the true system appearance at app launch BEFORE any overrides are set
    // This is the ONLY reliable way to know the actual iOS system appearance
    private var cachedSystemAppearance: LumoThemeMode

    private override init() {
        // Detect system appearance FIRST, before any UI initialization
        cachedSystemAppearance = ThemeManager.detectSystemAppearanceAtLaunch()
        super.init()
        setupSystemThemeObserver()
        updateCurrentMode()
    }

    // Static method to detect system appearance at launch
    private static func detectSystemAppearanceAtLaunch() -> LumoThemeMode {
        if #available(iOS 13.0, *) {
            let style = UITraitCollection.current.userInterfaceStyle
            return style == .dark ? .dark : .light
        }
        return .light
    }

    // MARK: - Public API

    func setup(webView: WKWebView) {
        self.webView = webView
        updateCurrentMode()
    }

    func setupThemeChangeListener() {
        guard let webView = webView else {
            Logger.shared.log("❌ ThemeManager: WebView not set")
            return
        }

        JSBridgeManager.shared.setupThemeChangeListener(in: webView) { result, error in
            if let error = error {
                Logger.shared.log("❌ Theme listener setup failed: \(error)")
            } else {
                Logger.shared.log("✅ Theme change listener setup successfully")
            }
        }
    }

    func readStoredTheme() {
        guard let webView = webView else {
            Logger.shared.log("❌ ThemeManager: WebView not set for theme reading")
            return
        }

        JSBridgeManager.shared.readStoredTheme(in: webView) { result, error in
            if let error = error {
                Logger.shared.log("❌ Theme reading failed: \(error)")
            } else {
                Logger.shared.log("✅ Theme reading script executed")
            }
        }
    }

    func updateSystemThemeMode(_ isDark: Bool) {
        let newSystemMode: LumoThemeMode = isDark ? .dark : .light

        Logger.shared.log(
            "📱 System theme mode update: isDark=\(isDark), newSystemMode=\(newSystemMode.rawValue), cachedSystemAppearance=\(cachedSystemAppearance.rawValue), currentTheme=\(currentTheme.rawValue), currentMode=\(currentMode.rawValue)"
        )

        let modeChanged = cachedSystemAppearance != newSystemMode

        if modeChanged {
            cachedSystemAppearance = newSystemMode
        }

        // Only update if we're on system theme AND the mode actually changed
        if currentTheme == .system && currentMode != cachedSystemAppearance {
            Logger.shared.log("📱 Theme is .system and mode changed - updating from \(currentMode.rawValue) to \(cachedSystemAppearance.rawValue)")
            currentMode = cachedSystemAppearance

            // Post notification to update native UI components
            Logger.shared.log("📱 Posting ThemeChangedFromWeb notification")
            NotificationCenter.default.post(
                name: NSNotification.Name("ThemeChangedFromWeb"),
                object: nil,
                userInfo: [
                    "theme": currentTheme.rawValue,
                    "mode": currentMode.rawValue,
                    "source": "system_update",
                ]
            )
        } else if currentTheme == .system && modeChanged {
            // Even if currentMode matches, post notification if system appearance actually changed
            // This ensures PaymentSheet and other components update
            Logger.shared.log("📱 System appearance changed, posting notification for UI update")
            NotificationCenter.default.post(
                name: NSNotification.Name("ThemeChangedFromWeb"),
                object: nil,
                userInfo: [
                    "theme": currentTheme.rawValue,
                    "mode": newSystemMode.rawValue,
                    "source": "system_appearance_change",
                ]
            )
        }
    }

    func setStoredTheme(_ theme: LumoTheme, mode: LumoThemeMode) {
        currentTheme = theme
        currentMode = mode

        // Notify app about theme change
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeChangedFromWeb"),
            object: nil,
            userInfo: [
                "theme": theme.rawValue,
                "mode": currentMode.rawValue,
                "source": "stored",
            ]
        )
    }

    func setDefaultSystemTheme() {
        // Default to system theme
        currentTheme = .system
        // currentMode will be set by ContentView's updateSystemThemeMode()
        // based on SwiftUI's colorScheme which is more reliable

        // Notify app about theme change (mode will be updated by ContentView)
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeChangedFromWeb"),
            object: nil,
            userInfo: [
                "theme": currentTheme.rawValue,
                "mode": currentMode.rawValue,
                "source": "default_system",
            ]
        )
    }

    func handleThemeChangeFromWeb(_ themeName: String) {
        let theme: LumoTheme
        switch themeName.lowercased() {
        case "light":
            theme = .light
        case "dark":
            theme = .dark
        case "system":
            theme = .system
        default:
            Logger.shared.log("⚠️ Unknown theme name: \(themeName)")
            return
        }

        currentTheme = theme

        // Update mode based on theme selection
        switch theme {
        case .light:
            currentMode = .light
        case .dark:
            currentMode = .dark
        case .system:
            currentMode = cachedSystemAppearance
        }

        // Notify app about theme change - ContentView will call updateSystemThemeMode()
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeChangedFromWeb"),
            object: nil,
            userInfo: [
                "theme": theme.rawValue,
                "mode": currentMode.rawValue,
                "themeName": themeName,
            ]
        )
    }

    // MARK: - Private Methods

    private func setupSystemThemeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // Also observe when app becomes active (covers coming back from Settings)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func systemThemeChanged() {
        // SwiftUI's colorScheme will automatically trigger ContentView's onChange
        // which will call updateSystemThemeMode with the correct value
    }

    func getSystemThemeMode() -> LumoThemeMode {
        // Return the cached system appearance
        cachedSystemAppearance
    }

    private func updateCurrentMode() {
        switch currentTheme {
        case .light:
            currentMode = .light
        case .dark:
            currentMode = .dark
        case .system:
            currentMode = cachedSystemAppearance
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

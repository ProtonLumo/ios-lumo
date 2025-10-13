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
    
    private override init() {
        super.init()
        setupSystemThemeObserver()
        updateCurrentMode()
    }
    
    // MARK: - Public API
    
    func setup(webView: WKWebView) {
        print("🎨 DEBUG: ThemeManager.setup() called with webView")
        self.webView = webView
        
        // Always start with system theme detection
        updateCurrentMode()
        
        Logger.shared.log("🎨 ThemeManager setup complete - initial theme: \(currentTheme), mode: \(currentMode)")
        print("🎨 DEBUG: ThemeManager setup complete - initial theme: \(currentTheme), mode: \(currentMode)")
        
        // Don't inject theme immediately - wait for stored theme to be read first
        // injectCurrentTheme() will be called by setStoredTheme() or when theme reading completes
    }
    
    func injectTheme(_ theme: LumoTheme, mode: LumoThemeMode) {
        guard let webView = webView else {
            Logger.shared.log("❌ ThemeManager: WebView not set")
            return
        }
        
        currentTheme = theme
        currentMode = mode
        
        Logger.shared.log("🎨 Injecting theme: \(theme.rawValue), mode: \(mode.rawValue)")
        
        JSBridgeManager.shared.injectTheme(
            theme: theme.rawValue,
            mode: mode.rawValue,
            in: webView
        ) { result, error in
            if let error = error {
                Logger.shared.log("❌ Theme injection failed: \(error)")
            } else {
                Logger.shared.log("✅ Theme injected successfully")
            }
        }
    }
    
    func setupThemeChangeListener() {
        guard let webView = webView else {
            Logger.shared.log("❌ ThemeManager: WebView not set")
            return
        }
        
        Logger.shared.log("🎨 Setting up theme change listener")
        
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
            print("❌ DEBUG: ThemeManager: WebView not set for theme reading")
            return
        }
        
        Logger.shared.log("🎨 Reading stored theme from localStorage")
        print("🎨 DEBUG: ThemeManager.readStoredTheme() called")
        
        JSBridgeManager.shared.readStoredTheme(in: webView) { result, error in
            if let error = error {
                Logger.shared.log("❌ Theme reading failed: \(error)")
                print("❌ DEBUG: Theme reading failed: \(error)")
            } else {
                Logger.shared.log("✅ Theme reading script executed")
                print("✅ DEBUG: Theme reading script executed")
            }
        }
    }
    
    func updateSystemThemeMode(_ isDark: Bool) {
        let newMode: LumoThemeMode = isDark ? .dark : .light
        
        Logger.shared.log("🎨 updateSystemThemeMode called - isDark: \(isDark), newMode: \(newMode), currentTheme: \(currentTheme), currentMode: \(currentMode)")
        print("🎨 DEBUG: updateSystemThemeMode - SwiftUI says isDark: \(isDark), newMode: \(newMode)")
        
        // Always update currentMode when using system theme, regardless of previous value
        // This ensures we stay in sync with SwiftUI's colorScheme
        if currentTheme == .system {
            let oldMode = currentMode
            currentMode = newMode
            
            if oldMode != newMode {
                Logger.shared.log("🎨 System theme mode updated from \(oldMode) to \(newMode)")
                print("🎨 DEBUG: System theme mode updated from \(oldMode) to \(newMode)")
                // injectCurrentTheme() // Don't inject - let web app manage localStorage
                
                // Notify the app to update its UI
                NotificationCenter.default.post(
                    name: NSNotification.Name("ThemeChangedFromWeb"),
                    object: nil,
                    userInfo: [
                        "theme": currentTheme.rawValue,
                        "mode": currentMode.rawValue,
                        "source": "system"
                    ]
                )
            } else {
                print("🎨 DEBUG: System theme mode unchanged: \(newMode)")
            }
        }
    }
    
    func setStoredTheme(_ theme: LumoTheme, mode: LumoThemeMode) {
        Logger.shared.log("🎨 Setting stored theme: \(theme) (\(mode))")
        
        currentTheme = theme
        currentMode = mode // Always use the mode provided - JavaScript already calculated it correctly
        
        Logger.shared.log("🎨 Theme set to: \(theme), mode: \(mode)")
        print("🎨 DEBUG: Theme set to: \(theme), mode: \(mode)")
        
        // Don't inject theme back to webview - let web app manage its own localStorage
        // injectCurrentTheme()
        
        // Notify app about theme change
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeChangedFromWeb"),
            object: nil,
            userInfo: [
                "theme": theme.rawValue,
                "mode": currentMode.rawValue,
                "source": "stored"
            ]
        )
    }
    
    func setDefaultSystemTheme() {
        Logger.shared.log("🎨 No stored theme found, using smart system default")
        print("🎨 DEBUG: setDefaultSystemTheme called")
        
        // Default to system theme
        currentTheme = .system
        // Don't set currentMode here - let ContentView's updateSystemThemeMode() set it
        // based on SwiftUI's colorScheme which is more reliable
        
        Logger.shared.log("🎨 Smart default: theme=\(currentTheme), mode will be set by SwiftUI")
        print("🎨 DEBUG: Smart default: theme=\(currentTheme), mode will be set by SwiftUI")
        
        // Don't inject theme here - let updateSystemThemeMode() handle it
        // This ensures we use the correct SwiftUI-detected mode
        
        // Notify app about theme change (mode will be updated by ContentView)
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeChangedFromWeb"),
            object: nil,
            userInfo: [
                "theme": currentTheme.rawValue,
                "mode": currentMode.rawValue,
                "source": "default_system"
            ]
        )
    }
    
    func handleThemeChangeFromWeb(_ themeName: String) {
        Logger.shared.log("🎨 Theme change received from web: \(themeName)")
        
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
        let mode: LumoThemeMode
        switch theme {
        case .light:
            mode = .light
        case .dark:
            mode = .dark
        case .system:
            mode = getSystemThemeMode()
        }
        
        currentMode = mode
        
        // Notify app about theme change if needed
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeChangedFromWeb"),
            object: nil,
            userInfo: [
                "theme": theme.rawValue,
                "mode": mode.rawValue,
                "themeName": themeName
            ]
        )
        
        Logger.shared.log("🎨 Theme updated to: \(theme) (\(mode))")
    }
    
    // MARK: - Private Methods
    
    private func setupSystemThemeObserver() {
        Logger.shared.log("🎨 Setting up system theme observer")
        
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
        
        // Observe trait collection changes directly if available
        if #available(iOS 13.0, *) {
            // This will be called by ContentView when colorScheme changes
            Logger.shared.log("🎨 iOS 13.0+ - relying on SwiftUI colorScheme changes")
        }
    }
    
    @objc private func systemThemeChanged() {
        Logger.shared.log("🎨 systemThemeChanged notification received")
        checkForSystemThemeChange()
    }
    
    private func checkForSystemThemeChange() {
        let newMode = getSystemThemeMode()
        
        Logger.shared.log("🎨 checkForSystemThemeChange - currentTheme: \(currentTheme), currentMode: \(currentMode), newMode: \(newMode)")
        
        // Only update if we're using system theme and the mode actually changed
        if currentTheme == .system && newMode != currentMode {
            Logger.shared.log("🎨 System theme changed from \(currentMode) to \(newMode)")
            currentMode = newMode
            // injectCurrentTheme() // Don't inject - let web app manage localStorage
            
            // Notify the app to update its UI
            NotificationCenter.default.post(
                name: NSNotification.Name("ThemeChangedFromWeb"),
                object: nil,
                userInfo: [
                    "theme": currentTheme.rawValue,
                    "mode": currentMode.rawValue,
                    "source": "system_change"
                ]
            )
        }
    }
    
    private func getSystemThemeMode() -> LumoThemeMode {
        if #available(iOS 13.0, *) {
            // Try to get trait collection from key window for more reliable detection
            let userInterfaceStyle: UIUserInterfaceStyle
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                userInterfaceStyle = keyWindow.traitCollection.userInterfaceStyle
                Logger.shared.log("🎨 System theme detected from keyWindow: \(userInterfaceStyle.rawValue) (\(userInterfaceStyle == .dark ? "dark" : "light"))")
                print("🎨 DEBUG: keyWindow userInterfaceStyle: \(userInterfaceStyle.rawValue) (\(userInterfaceStyle == .dark ? "dark" : "light"))")
            } else {
                // Fallback to current trait collection
                userInterfaceStyle = UITraitCollection.current.userInterfaceStyle
                Logger.shared.log("🎨 System theme detected from UITraitCollection.current: \(userInterfaceStyle.rawValue) (\(userInterfaceStyle == .dark ? "dark" : "light"))")
                print("🎨 DEBUG: UITraitCollection.current userInterfaceStyle: \(userInterfaceStyle.rawValue) (\(userInterfaceStyle == .dark ? "dark" : "light"))")
            }
            
            // Additional debug: check all connected scenes and windows
            print("🎨 DEBUG: Connected scenes count: \(UIApplication.shared.connectedScenes.count)")
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    print("🎨 DEBUG: WindowScene: \(windowScene), windows count: \(windowScene.windows.count)")
                    for (index, window) in windowScene.windows.enumerated() {
                        print("🎨 DEBUG: Window[\(index)]: isKeyWindow=\(window.isKeyWindow), userInterfaceStyle=\(window.traitCollection.userInterfaceStyle.rawValue)")
                    }
                }
            }
            
            switch userInterfaceStyle {
            case .dark:
                return .dark
            case .light, .unspecified:
                return .light
            @unknown default:
                return .light
            }
        } else {
            Logger.shared.log("🎨 iOS < 13.0, defaulting to light mode")
            return .light
        }
    }
    
    private func updateCurrentMode() {
        let oldMode = currentMode
        switch currentTheme {
        case .light:
            currentMode = .light
        case .dark:
            currentMode = .dark
        case .system:
            currentMode = getSystemThemeMode()
        }
        Logger.shared.log("🎨 ThemeManager updateCurrentMode - theme: \(currentTheme), changed from \(oldMode) to \(currentMode)")
    }
    
    private func injectCurrentTheme() {
        injectTheme(currentTheme, mode: currentMode)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}



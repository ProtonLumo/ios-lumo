import SwiftUI
import Combine

/// Centralized theme provider that manages dark mode state for the entire app
/// Uses @EnvironmentObject to propagate theme changes to all views
class ThemeProvider: ObservableObject {
    /// The single source of truth for dark mode state
    @Published var isDarkMode: Bool = false
    
    /// Reference to system colorScheme - updated from parent view
    var systemColorScheme: ColorScheme = .light
    
    /// Singleton instance
    static let shared = ThemeProvider()
    
    private init() {
        // Initialize with system appearance
        updateTheme()
    }
    
    /// Update theme based on web app preferences and system appearance
    /// Should be called when:
    /// - System colorScheme changes
    /// - Web app theme preference changes
    /// - App launches
    func updateTheme(systemColorScheme: ColorScheme? = nil) {
        if let scheme = systemColorScheme {
            self.systemColorScheme = scheme
        }
        
        let themeManager = ThemeManager.shared
        let shouldBeDark: Bool
        
        if themeManager.currentTheme == .system {
            // System theme - use the environment colorScheme
            shouldBeDark = self.systemColorScheme == .dark
            Logger.shared.log("🎨 ThemeProvider: Theme is SYSTEM, using systemColorScheme=\(self.systemColorScheme == .dark ? "dark" : "light")")
        } else {
            // Light or Dark theme explicitly set - use currentMode from localStorage
            shouldBeDark = themeManager.currentMode == .dark
            Logger.shared.log("🎨 ThemeProvider: Theme is explicit (\(themeManager.currentTheme.rawValue)), using currentMode=\(themeManager.currentMode.rawValue == 1 ? "dark" : "light")")
        }
        
        if isDarkMode != shouldBeDark {
            Logger.shared.log("🎨 ThemeProvider updating isDarkMode from \(isDarkMode) to \(shouldBeDark)")
            // Dispatch to next run loop to avoid "Publishing changes from within view updates" error
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isDarkMode = shouldBeDark
                }
            }
        }
    }
    
    /// Convenience computed properties
    var backgroundColor: Color {
        isDarkMode ? Color(hex: 0x16141c) : .white
    }
    
    var textColor: Color {
        isDarkMode ? .white : .black
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? Color.gray.opacity(0.7) : Color(.systemGray)
    }
}


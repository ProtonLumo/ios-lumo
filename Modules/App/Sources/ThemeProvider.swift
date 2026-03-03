import Combine
import SwiftUI

/// Centralized theme provider that manages dark mode state for the entire app
/// Uses @EnvironmentObject to propagate theme changes to all views
final class ThemeProvider: ObservableObject {
    /// Reference to system colorScheme - updated from parent view
    @Published var systemColorScheme: ColorScheme?

    init() {
        // Initialize with system appearance
        updateTheme()
    }

    /// Update theme based on web app preferences and system appearance
    /// Should be called when:
    /// - System colorScheme changes
    /// - Web app theme preference changes
    /// - App launches
    func updateTheme() {
        let themeManager = ThemeManager.shared

        switch themeManager.currentTheme {
        case .dark:
            systemColorScheme = .dark
        case .light:
            systemColorScheme = .light
        case .system:
            systemColorScheme = nil
        }
    }
}

import LumoCore
import SwiftUI

@MainActor
final class ThemeStore: ObservableObject {
    @Published private(set) var colorScheme: ColorScheme? = nil

    func apply(theme: WebColorScheme) {
        switch theme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil
        }
    }
}

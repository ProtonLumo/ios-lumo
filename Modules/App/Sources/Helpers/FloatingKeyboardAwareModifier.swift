import SwiftUI
import UIKit

extension View {
    /// Fixes the iPad floating keyboard blank space issue.
    ///
    /// When the iPad keyboard switches from docked to floating, SwiftUI leaves a blank gap at the
    /// bottom of the screen because it doesn't reclaim the space it reserved for the keyboard.
    /// This modifier disables SwiftUI's keyboard handling on iPad and lets WKWebView manage it
    /// instead — the same way Safari does (the keyboard overlays the content and the web view
    /// scrolls to keep the focused input visible).
    ///
    /// On iPhone, this modifier does nothing — the default keyboard behavior is kept.
    @ViewBuilder
    func floatingKeyboardAware(device: UIDevice = .current) -> some View {
        if device.userInterfaceIdiom == .pad {
            ignoresSafeArea(.keyboard)
        } else {
            self
        }
    }
}

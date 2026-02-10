import Foundation

/// View-level state that drives the composer UI
///
/// This combines the synchronized `WebComposerState` from WebView with local UI state.
struct ComposerViewState: Equatable, Copying {
    /// Current text in composer input (local UI state, not synced with web)
    var currentText: String
    /// Local processing state for optimistic UI updates
    ///
    /// Set to `true` immediately when sending a prompt, before web confirms.
    /// Reset to `false` when web state returns to `.idle`.
    /// This provides instant feedback by showing stop button during network delay.
    var isProcessing: Bool
    /// Whether the WebView has loaded and is ready for interaction
    var isWebViewReady: Bool
    /// State synchronized from WebView
    var webState: WebComposerState

    /// Action button state for ComposerView
    ///
    /// This drives the UI for the main action button:
    /// - `.none`: No button shown (idle + empty text + not processing)
    /// - `.send`: Send button shown (idle + has text + not processing)
    /// - `.stop`: Stop button shown (processing OR working)
    ///
    /// The button shows `.stop` immediately when user taps send (via `isProcessing`),
    /// providing instant feedback before web confirms the state change.
    var actionButton: ComposerView.ActionButtonState {
        guard isWebViewReady else {
            return .none
        }

        guard !isProcessing, webState.mode == .idle else {
            return .stop
        }

        return hasNonEmptyText ? .send : .none
    }

    /// Whether there's text in the input (after trimming whitespace)
    private var hasNonEmptyText: Bool {
        !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension ComposerViewState {
    static var initial: Self {
        .init(
            currentText: "",
            isProcessing: false,
            isWebViewReady: false,
            webState: .initial
        )
    }
}

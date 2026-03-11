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
    /// Currently presented sheet, or `nil` when no sheet is shown
    var activeSheet: ActiveSheet?
    /// In-memory cache mapping file IDs to their base64 preview strings
    ///
    /// The WebAPI only returns `preview` on the first upload; subsequent state updates omit it.
    /// This cache preserves previews for the duration of the session.
    private var filePreviewsCache: [String: String]

    init(
        currentText: String,
        isProcessing: Bool,
        isWebViewReady: Bool,
        webState: WebComposerState,
        activeSheet: ActiveSheet?
    ) {
        self.currentText = currentText
        self.isProcessing = isProcessing
        self.isWebViewReady = isWebViewReady
        self.webState = webState
        self.activeSheet = activeSheet
        self.filePreviewsCache = [:]
    }

    /// Action button state for ComposerView
    ///
    /// This drives the UI for the main action button:
    /// - `.none` - No button shown
    /// - `.send` - Send button shown
    /// - `.stop` - Stop button shown
    ///
    /// **Instant feedback:**
    /// Button switches to `.stop` immediately when user taps send (via `isProcessing`),
    /// providing instant UI feedback before the web application confirms state change.
    var actionButton: ComposerView.ActionButtonState {
        guard isWebViewReady else {
            return .none
        }

        guard !isProcessing, webState.mode == .idle else {
            return .stop
        }

        return hasNonEmptyText ? .send : .none
    }

    /// Returns a new state with the given `webState` applied, merging file previews with the cache.
    ///
    /// - Files arriving with a non-nil `preview` are stored in the cache.
    /// - Files arriving with a nil `preview` are enriched from the cache if available.
    func copy(applyingWebState webState: WebComposerState) -> Self {
        var updated = self

        for file in webState.attachedFiles {
            if let preview = file.preview {
                updated.filePreviewsCache[file.id] = preview
            }
        }

        let updatedAttachedFiles = webState.attachedFiles.map { file in
            guard
                file.preview == nil,
                let cachedPreview = updated.filePreviewsCache[file.id]
            else {
                return file
            }

            return File(id: file.id, name: file.name, type: file.type, preview: cachedPreview)
        }

        let updatedWebState = webState.copy(attachedFiles: updatedAttachedFiles)

        return updated.copy(\.webState, to: updatedWebState)
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
            webState: .initial,
            activeSheet: .none
        )
    }
}

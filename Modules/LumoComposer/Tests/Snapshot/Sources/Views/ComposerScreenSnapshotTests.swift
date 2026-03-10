import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

@MainActor
struct ComposerScreenSnapshotTests {
    @Test(.lottiePaused(at: 0.2))
    func composerScreenInitial() {
        let sut = makeSUT(initialState: .initial)

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }

    @Test(.lottiePaused(at: 0.0))
    func composerScreenProcessingPrompt() {
        let state: ComposerViewState = .initial
            .copy(
                \.webState,
                to: .init(
                    mode: .working,
                    model: .auto,
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: true,
                    isCreateImageEnabled: false,
                    isVisible: true,
                    showTermsAndPrivacy: false,
                    attachedFiles: [
                        .init(id: "<id_1>", name: "selfie.png", type: .image, preview: .none),
                        .init(id: "<id_2>", name: "information_about_me.pdf", type: .pdf, preview: .none),
                        .init(id: "<id_3>", name: "data", type: .protonSheet, preview: .none),
                    ],
                    featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true)
                )
            )
            .copy(\.currentText, to: "")
            .copy(\.isProcessing, to: true)
            .copy(\.isWebViewReady, to: true)
        let sut = makeSUT(initialState: state)

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }

    @Test(.lottiePaused(at: 0.0))
    func composerScreenIdle() {
        let state: ComposerViewState = .initial
            .copy(\.isWebViewReady, to: true)
        let sut = makeSUT(initialState: state)

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }

    @Test(.lottiePaused(at: 0.0))
    func composerScreenHidden() {
        let state: ComposerViewState = .initial
            .copy(
                \.webState,
                to: .init(
                    mode: .idle,
                    model: .auto,
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: false,
                    isCreateImageEnabled: false,
                    isVisible: false,
                    showTermsAndPrivacy: false,
                    attachedFiles: [],
                    featureFlags: .initial
                )
            )
        let sut = makeSUT(initialState: state)

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }

    // MARK: - Private

    private func makeSUT(initialState: ComposerViewState) -> some View {
        ComposerScreen(
            initialState: initialState,
            webBridge: WebComposerBridge(),
            isWebViewReady: false,
            webContent: { EmptyView() }
        )
    }
}

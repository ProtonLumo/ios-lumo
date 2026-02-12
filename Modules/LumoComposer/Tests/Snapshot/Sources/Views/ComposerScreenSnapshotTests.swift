import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

@MainActor
struct ComposerScreenSnapshotTests {
    @Test(.lottiePaused(at: 0.2))
    func composerScreenInitial() {
        let sut = ComposerScreen(
            initialState: .initial,
            webBridge: WebComposerBridge(),
            isWebViewReady: false
        )

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }

    @Test(.lottiePaused(at: 0.0))
    func composerScreenProcessingPrompt() {
        let state: ComposerViewState = .initial
            .copy(
                \.webState,
                to: .init(
                    mode: .working,
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: true,
                    isVisible: true,
                    showTermsAndPrivacy: false,
                    attachedFiles: [
                        .init(id: "<id_1>", name: "selfie.png", type: .image),
                        .init(id: "<id_2>", name: "information_about_me.pdf", type: .pdf),
                        .init(id: "<id_3>", name: "data", type: .protonSheet),
                    ])
            )
            .copy(\.currentText, to: "")
            .copy(\.isProcessing, to: true)
            .copy(\.isWebViewReady, to: true)

        let sut = ComposerScreen(
            initialState: state,
            webBridge: WebComposerBridge(),
            isWebViewReady: false
        )

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }

    @Test(.lottiePaused(at: 0.0))
    func composerScreenHidden() {
        let state: ComposerViewState = .initial
            .copy(
                \.webState,
                to: .init(
                    mode: .idle,
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: false,
                    isVisible: false,
                    showTermsAndPrivacy: false,
                    attachedFiles: []
                )
            )

        let sut = ComposerScreen(
            initialState: state,
            webBridge: WebComposerBridge(),
            isWebViewReady: false
        )

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }
}

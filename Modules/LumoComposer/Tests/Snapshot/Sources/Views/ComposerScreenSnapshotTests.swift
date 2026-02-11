import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

struct ComposerScreenSnapshotTests {
    @MainActor
    @Test(.lottiePaused(at: 0.2))
    func composerScreen() {
        let sut = ComposerScreen(
            initialState: .initial.copy(\.isWebViewReady, to: true),
            webBridge: WebComposerBridge(),
            isWebViewReady: false
        )

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }
}

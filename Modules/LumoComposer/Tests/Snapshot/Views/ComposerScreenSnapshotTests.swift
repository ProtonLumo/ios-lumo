import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

struct ComposerScreenSnapshotTests {
    @Test
    @MainActor
    func composerScreen() {
        let sut = ComposerScreen(isSnapshotMode: true)

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }
}

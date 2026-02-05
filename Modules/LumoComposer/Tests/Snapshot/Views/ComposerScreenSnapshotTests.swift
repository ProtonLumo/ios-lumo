import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

@MainActor
struct ComposerScreenSnapshotTests {
    @Test
    func composerScreen() {
        let sut = ComposerScreen(isSnapshotMode: true)

        assertSnapshotsOnEdgeDevices(of: sut, drawHierarchyInKeyWindow: true)
    }
}

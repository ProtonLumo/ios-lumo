import LumoDesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

struct ToolsSheetViewSnapshotTests {
    struct TestCase: Sendable {
        let isWebSearchEnabled: Bool
        let testName: String
    }

    static let testCases: [TestCase] = [
        TestCase(isWebSearchEnabled: false, testName: "web_search_off"),
        TestCase(isWebSearchEnabled: true, testName: "web_search_on"),
    ]

    @Test(arguments: testCases)
    @MainActor
    func toolsSheetView(testCase: TestCase) {
        assertSnapshotsOnEdgeDevices(
            of: sut(testCase: testCase),
            drawHierarchyInKeyWindow: true,
            testName: testCase.testName
        )
    }

    // MARK: - Private

    private func sut(testCase: TestCase) -> some View {
        ToolsSheetView(
            isWebSearchEnabled: testCase.isWebSearchEnabled,
            action: { _ in }
        )
        .frame(height: 300)
        .background(DS.Color.Background.norm)
    }
}

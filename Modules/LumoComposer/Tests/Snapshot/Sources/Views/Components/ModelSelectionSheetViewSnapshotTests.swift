import LumoDesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

struct ModelSelectionSheetViewSnapshotTests {
    struct TestCase: Sendable {
        let selectedModel: WebComposerState.Model
        let testName: String
    }

    static let testCases: [TestCase] = [
        TestCase(selectedModel: .auto, testName: "selected_auto"),
        TestCase(selectedModel: .fast, testName: "selected_fast"),
        TestCase(selectedModel: .thinking, testName: "selected_thinking"),
    ]

    @Test(arguments: testCases)
    @MainActor
    func modelSelectionSheetView(testCase: TestCase) {
        assertSnapshotsOnEdgeDevices(of: sut(testCase: testCase), testName: testCase.testName)
    }

    // MARK: - Private

    private func sut(testCase: TestCase) -> some View {
        ModelSelectionSheetView(
            selectedModel: testCase.selectedModel,
            action: { _ in }
        )
        .background(DS.Color.Background.norm)
    }
}

import LumoDesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

struct ModelSelectionSheetViewSnapshotTests {
    struct TestCase: Sendable {
        let modelTier: WebComposerState.ModelTier
        let testName: String
    }

    static let testCases: [TestCase] = [
        TestCase(modelTier: .auto, testName: "selected_auto"),
        TestCase(modelTier: .fast, testName: "selected_fast"),
        TestCase(modelTier: .thinking, testName: "selected_thinking"),
    ]

    @Test(arguments: testCases)
    @MainActor
    func modelSelectionSheetView(testCase: TestCase) {
        assertSnapshotsOnEdgeDevices(of: sut(testCase: testCase), testName: testCase.testName)
    }

    // MARK: - Private

    private func sut(testCase: TestCase) -> some View {
        ModelSelectionSheetView(
            selectedModel: testCase.modelTier,
            action: { _ in }
        )
        .background(DS.Color.Background.norm)
    }
}

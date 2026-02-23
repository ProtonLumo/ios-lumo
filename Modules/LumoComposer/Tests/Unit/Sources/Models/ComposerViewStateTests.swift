import Foundation
import Testing

@testable import LumoComposer

struct ComposerViewStateTests {
    @Test
    func initialState_HasCorrectValues() {
        let sut = ComposerViewState.initial

        #expect(
            sut
                == ComposerViewState(
                    currentText: "",
                    isProcessing: false,
                    isWebViewReady: false,
                    webState: .init(
                        mode: .idle,
                        modelType: .auto,
                        isGhostModeEnabled: false,
                        isWebSearchEnabled: false,
                        isCreateImageEnabled: false,
                        isVisible: true,
                        showTermsAndPrivacy: true,
                        attachedFiles: []
                    )
                )
        )
    }

    // MARK: - Action Button

    struct TestCase {
        let given: ComposerViewState
        let expected: ComposerView.ActionButtonState
    }

    @Test(
        arguments: [
            TestCase(given: .testData(currentText: "", isProcessing: false, mode: .idle), expected: .none),
            TestCase(given: .testData(currentText: "   \n  ", isProcessing: false, mode: .idle), expected: .none),
            TestCase(given: .testData(currentText: "\n\n   \n  \n", isProcessing: false, mode: .idle), expected: .none),
            TestCase(given: .testData(currentText: " ", isProcessing: false, mode: .idle), expected: .none),
            TestCase(given: .testData(currentText: "\t", isProcessing: false, mode: .idle), expected: .none),
            TestCase(given: .testData(currentText: "What is AI?", isProcessing: false, isWebViewReady: false, mode: .idle), expected: .none),
            TestCase(given: .testData(currentText: "", isProcessing: true, isWebViewReady: false, mode: .idle), expected: .none),

            TestCase(given: .testData(currentText: "What is AI?", isProcessing: false, mode: .idle), expected: .send),
            TestCase(given: .testData(currentText: "  Hello  \n", isProcessing: false, mode: .idle), expected: .send),
            TestCase(given: .testData(currentText: "Line 1\nLine 2\nLine 3", isProcessing: false, mode: .idle), expected: .send),

            TestCase(given: .testData(currentText: "", isProcessing: true, mode: .idle), expected: .stop),
            TestCase(given: .testData(currentText: "Test", isProcessing: true, mode: .idle), expected: .stop),
            TestCase(given: .testData(currentText: "", isProcessing: false, mode: .working), expected: .stop),
            TestCase(given: .testData(currentText: "Test", isProcessing: false, mode: .working), expected: .stop),
            TestCase(given: .testData(currentText: "", isProcessing: true, mode: .working), expected: .stop),
        ]
    )
    func actionButton(testCase: TestCase) {
        #expect(testCase.given.actionButton == testCase.expected)
    }
}

private extension ComposerViewState {
    static func testData(
        currentText: String,
        isProcessing: Bool,
        isWebViewReady: Bool = true,
        mode: WebComposerState.Mode
    ) -> Self {
        ComposerViewState(
            currentText: currentText,
            isProcessing: isProcessing,
            isWebViewReady: isWebViewReady,
            webState: WebComposerState(
                mode: mode,
                modelType: .auto,
                isGhostModeEnabled: false,
                isWebSearchEnabled: false,
                isCreateImageEnabled: false,
                isVisible: true,
                showTermsAndPrivacy: true,
                attachedFiles: []
            )
        )
    }
}

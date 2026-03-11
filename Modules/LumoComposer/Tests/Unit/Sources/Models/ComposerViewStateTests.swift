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
                        model: .auto,
                        isGhostModeEnabled: false,
                        isWebSearchEnabled: false,
                        isCreateImageEnabled: false,
                        isVisible: true,
                        showTermsAndPrivacy: true,
                        attachedFiles: [],
                        featureFlags: .init(isImageGenEnabled: false, isModelSelectionEnabled: false)
                    ),
                    activeSheet: .none
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

    // MARK: - File previews cache

    @Test
    func copyApplyingWebState_WhenPreviewIsNilAndCacheIsEmpty_PreviewRemainsNil() {
        let state = ComposerViewState.initial
        let file = File.testData(id: "1", preview: nil)

        let result = state.copy(applyingWebState: .testData(attachedFiles: [file]))

        #expect(result.webState.attachedFiles.first?.preview == nil)
    }

    @Test
    func copyApplyingWebState_WhenPreviewIsProvided_ItAppearsInResult() {
        let state = ComposerViewState.initial
        let file = File.testData(id: "1", preview: "base64data")

        let result = state.copy(applyingWebState: .testData(attachedFiles: [file]))

        #expect(result.webState.attachedFiles.first?.preview == "base64data")
    }

    @Test
    func copyApplyingWebState_WhenPreviewIsNilAndCacheHasPreview_PreviewIsRestoredFromCache() {
        let state = ComposerViewState.initial
        let preview = "base64data"

        let stateAfterFirstUpdate = state.copy(
            applyingWebState: .testData(attachedFiles: [.testData(id: "1", preview: preview)])
        )
        let stateAfterSecondUpdate = stateAfterFirstUpdate.copy(
            applyingWebState: .testData(attachedFiles: [.testData(id: "1", preview: nil)])
        )

        #expect(stateAfterSecondUpdate.webState.attachedFiles.first?.preview == preview)
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
                model: .auto,
                isGhostModeEnabled: false,
                isWebSearchEnabled: false,
                isCreateImageEnabled: false,
                isVisible: true,
                showTermsAndPrivacy: true,
                attachedFiles: [],
                featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true)
            ),
            activeSheet: .none
        )
    }
}

private extension WebComposerState {
    static func testData(attachedFiles: [File]) -> Self {
        .init(
            mode: .idle,
            model: .auto,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isCreateImageEnabled: false,
            isVisible: true,
            showTermsAndPrivacy: true,
            attachedFiles: attachedFiles,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true)
        )
    }
}

private extension File {
    static func testData(id: String, preview: String?) -> Self {
        .init(id: id, name: "file.png", type: .image, preview: preview)
    }
}

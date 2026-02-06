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
                    webState: .init(
                        mode: .idle,
                        isGhostModeEnabled: false,
                        isWebSearchEnabled: false,
                        isVisible: false,
                        showTermsAndPrivacy: false,
                        attachedFiles: []
                    )
                )
        )
    }

    // MARK: - Action Button

    @Test
    func actionButton_IdleEmptyTextNotProcessing_ReturnsNone() {
        let sut = ComposerViewState.testData(
            currentText: "",
            isProcessing: false,
            mode: .idle
        )

        #expect(sut.actionButton == .none)
    }

    @Test
    func actionButton_IdleHasTextNotProcessing_ReturnsSend() {
        let sut = ComposerViewState.testData(
            currentText: "What is AI?",
            isProcessing: false,
            mode: .idle
        )

        #expect(sut.actionButton == .send)
    }

    @Test
    func actionButton_IdleHasTextWithWhitespaceNotProcessing_ReturnsSend() {
        let sut = ComposerViewState.testData(
            currentText: "  Hello  \n",
            isProcessing: false,
            mode: .idle
        )

        #expect(sut.actionButton == .send)
    }

    @Test
    func actionButton_IdleOnlyWhitespacesNotProcessing_ReturnsNone() {
        let sut = ComposerViewState.testData(
            currentText: "   \n  ",
            isProcessing: false,
            mode: .idle
        )

        #expect(sut.actionButton == .none)
    }

    @Test
    func actionButton_ProcessingRegardlessOfModeAndText_ReturnsStop() {
        // isProcessing=true, mode=.idle, empty text
        let case1 = ComposerViewState.testData(
            currentText: "",
            isProcessing: true,
            mode: .idle
        )
        #expect(case1.actionButton == .stop)

        let case2 = ComposerViewState.testData(
            currentText: "Test",
            isProcessing: true,
            mode: .idle
        )
        #expect(case2.actionButton == .stop)
    }

    @Test
    func actionButton_WorkingModeRegardlessOfTextAndIsProcessing_ReturnsStop() {
        // mode=.working, isProcessing=false, empty text
        let case1 = ComposerViewState.testData(
            currentText: "",
            isProcessing: false,
            mode: .working
        )
        #expect(case1.actionButton == .stop)

        // mode=.working, isProcessing=false, has text
        let case2 = ComposerViewState.testData(
            currentText: "Test",
            isProcessing: false,
            mode: .working
        )
        #expect(case2.actionButton == .stop)
    }

    @Test
    func actionButton_WhenBothProcessingAndWorking_ReturnsStop() {
        let sut = ComposerViewState.testData(
            currentText: "",
            isProcessing: true,
            mode: .working
        )

        #expect(sut.actionButton == .stop)
    }

    // MARK: - Edge Cases

    @Test
    func actionButton_MultilineText_ReturnsSend() {
        let sut = ComposerViewState.testData(
            currentText: "Line 1\nLine 2\nLine 3",
            isProcessing: false,
            mode: .idle
        )

        #expect(sut.actionButton == .send)
    }

    @Test
    func actionButtonMultilineWhitespace() {
        let sut = ComposerViewState.testData(
            currentText: "\n\n   \n  \n",
            isProcessing: false,
            mode: .idle
        )

        #expect(sut.actionButton == .none)
    }

    @Test
    func actionButtonSingleSpace() {
        let viewState = ComposerViewState.testData(
            currentText: " ",
            isProcessing: false,
            mode: .idle
        )

        #expect(viewState.actionButton == .none)
    }

    @Test
    func actionButtonTabCharacter() {
        let sut = ComposerViewState.testData(
            currentText: "\t",
            isProcessing: false,
            mode: .idle
        )

        #expect(sut.actionButton == .none)
    }
}

private extension ComposerViewState {
    static func testData(
        currentText: String,
        isProcessing: Bool,
        mode: WebComposerState.Mode
    ) -> Self {
        ComposerViewState(
            currentText: currentText,
            isProcessing: isProcessing,
            webState: WebComposerState(
                mode: mode,
                isGhostModeEnabled: false,
                isWebSearchEnabled: false,
                isVisible: true,
                showTermsAndPrivacy: true,
                attachedFiles: []
            )
        )
    }
}

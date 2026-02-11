import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

struct ComposerViewSnapshotTests {
    struct TestCase {
        let initialText: String
        let files: [File]
        let isGhostModeEnabled: Bool
        let isWebSearchEnabled: Bool
        let areButtonsDisabled: Bool
        let actionButton: ComposerView.ActionButtonState
        let testName: String
    }

    /// Idle state - empty composer
    static let idleEmptyComposer: [TestCase] = [
        TestCase(
            initialText: "",
            files: [],
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: true,
            actionButton: .none,
            testName: "idle_empty_disabled"
        ),
        TestCase(
            initialText: "",
            files: [],
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .none,
            testName: "idle_empty_web_search"
        ),
        TestCase(
            initialText: "",
            files: [],
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .none,
            testName: "idle_empty_ghost_mode"
        ),
        TestCase(
            initialText: "",
            files: [],
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .none,
            testName: "idle_empty_ghost_mode_web_search"
        ),
    ]

    /// Short prompt
    static let shortPrompt: [TestCase] = [
        TestCase(
            initialText: "What is AI?",
            files: [],
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "short_prompt_web_search"
        ),
        TestCase(
            initialText: "Explain quantum physics",
            files: [],
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "short_prompt_ghost_mode"
        ),
    ]

    /// Long prompt
    static let longPrompt: [TestCase] = [
        TestCase(
            initialText:
                "Can you help me understand the differences between supervised and unsupervised learning? I'm particularly interested in real-world examples and how these concepts apply to modern AI systems.",
            files: [],
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "long_prompt_web_search"
        ),
        TestCase(
            initialText:
                "Explain quantum computing in simple terms. What are qubits, how do they differ from classical bits, and what are the main challenges in building practical quantum computers?",
            files: [],
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "long_prompt_ghost_mode_web_search"
        ),
    ]

    /// Send state - ready to send
    static let readyToSend: [TestCase] = [
        TestCase(
            initialText: "Tell me a story",
            files: [],
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "send_state_ready"
        ),
        TestCase(
            initialText: "Search for latest news",
            files: [],
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "send_state_ready_web_search"
        ),
    ]

    /// Sending state
    static let sending: [TestCase] = [
        TestCase(
            initialText: "",
            files: [],
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .stop,
            testName: "sending_state"
        ),
        TestCase(
            initialText: "",
            files: [],
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .stop,
            testName: "sending_state_ghost_mode_web_search"
        ),
    ]

    /// With files
    static let withFiles: [TestCase] = [
        // One file
        TestCase(
            initialText: "Analyze this document",
            files: [.init(id: "1", name: "Report.pdf", type: .pdf)],
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "with_one_file"
        ),
        TestCase(
            initialText: "Analyze this document",
            files: [.init(id: "1", name: "Report.pdf", type: .pdf)],
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "with_one_file_ghost_mode_web_search"
        ),
        // Two files
        TestCase(
            initialText: "Compare these documents",
            files: [
                .init(id: "1", name: "Contract_v1.pdf", type: .pdf),
                .init(id: "2", name: "Budget.xls", type: .xls),
            ],
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "with_two_files"
        ),
        TestCase(
            initialText: "Compare these documents",
            files: [
                .init(id: "1", name: "Contract_v1.pdf", type: .pdf),
                .init(id: "2", name: "Budget.xls", type: .xls),
            ],
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "with_two_files_ghost_mode"
        ),
        // Many files
        TestCase(
            initialText: "Process all these files",
            files: [
                .init(id: "1", name: "Report.pdf", type: .pdf),
                .init(id: "2", name: "Data.xls", type: .xls),
                .init(id: "3", name: "Slides.ppt", type: .ppt),
                .init(id: "4", name: "Image.jpg", type: .image),
                .init(id: "5", name: "Video.mp4", type: .video),
            ],
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "with_many_files"
        ),
        TestCase(
            initialText: "Process all these files",
            files: [
                .init(id: "1", name: "Report.pdf", type: .pdf),
                .init(id: "2", name: "Data.xls", type: .xls),
                .init(id: "3", name: "Slides.ppt", type: .ppt),
                .init(id: "4", name: "Image.jpg", type: .image),
                .init(id: "5", name: "Video.mp4", type: .video),
            ],
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            testName: "with_many_files_ghost_mode_web_search"
        ),
    ]

    @Test(arguments: idleEmptyComposer + shortPrompt + longPrompt + readyToSend + sending + withFiles)
    @MainActor
    func composerView(testCase: TestCase) {
        assertSnapshotsOnEdgeDevices(of: sut(testCase: testCase), testName: testCase.testName)
    }

    // MARK: - Private

    private func sut(testCase: TestCase) -> some View {
        VStack {
            Spacer()
            ComposerView(
                text: .constant(testCase.initialText),
                files: testCase.files,
                isGhostModeEnabled: testCase.isGhostModeEnabled,
                isWebSearchEnabled: testCase.isWebSearchEnabled,
                areButtonsDisabled: testCase.areButtonsDisabled,
                actionButton: testCase.actionButton,
                action: { _ in }
            )
        }
    }
}

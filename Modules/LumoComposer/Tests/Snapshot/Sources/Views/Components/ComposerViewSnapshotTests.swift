import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

struct ComposerViewSnapshotTests {
    struct TestCase {
        let initialText: String
        let files: [File]
        let model: WebComposerState.Model
        let isCreateImageEnabled: Bool
        let isGhostModeEnabled: Bool
        let isWebSearchEnabled: Bool
        let areButtonsDisabled: Bool
        let actionButton: ComposerView.ActionButtonState
        let featureFlags: WebComposerState.FeatureFlags
        let testName: String
    }

    /// Idle state - empty composer
    static let idleEmptyComposer: [TestCase] = [
        TestCase(
            initialText: "",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: true,
            actionButton: .none,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "idle_empty_disabled"
        ),
        TestCase(
            initialText: "",
            files: [],
            model: .thinking,
            isCreateImageEnabled: true,
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .none,
            featureFlags: .init(isImageGenEnabled: false, isModelSelectionEnabled: true),
            testName: "idle_empty_web_search"
        ),
        TestCase(
            initialText: "",
            files: [],
            model: .fast,
            isCreateImageEnabled: false,
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .none,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "idle_empty_ghost_mode"
        ),
        TestCase(
            initialText: "",
            files: [],
            model: .auto,
            isCreateImageEnabled: true,
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .none,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "idle_empty_ghost_mode_web_search"
        ),
    ]

    /// Short prompt
    static let shortPrompt: [TestCase] = [
        TestCase(
            initialText: "What is AI?",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "short_prompt_web_search"
        ),
        TestCase(
            initialText: "Explain quantum physics",
            files: [],
            model: .thinking,
            isCreateImageEnabled: false,
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "short_prompt_ghost_mode"
        ),
    ]

    /// Long prompt
    static let longPrompt: [TestCase] = [
        TestCase(
            initialText:
                "Can you help me understand the differences between supervised and unsupervised learning? I'm particularly interested in real-world examples and how these concepts apply to modern AI systems.",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "long_prompt_web_search"
        ),
        TestCase(
            initialText:
                "Explain quantum computing in simple terms. What are qubits, how do they differ from classical bits, and what are the main challenges in building practical quantum computers?",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "long_prompt_ghost_mode_web_search"
        ),
    ]

    /// Send state - ready to send
    static let readyToSend: [TestCase] = [
        TestCase(
            initialText: "Tell me a story",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "send_state_ready"
        ),
        TestCase(
            initialText: "Search for latest news",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "send_state_ready_web_search"
        ),
    ]

    /// Sending state
    static let sending: [TestCase] = [
        TestCase(
            initialText: "",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .stop,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "sending_state"
        ),
        TestCase(
            initialText: "",
            files: [],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .stop,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "sending_state_ghost_mode_web_search"
        ),
    ]

    /// With files
    static let withFiles: [TestCase] = [
        // One file
        TestCase(
            initialText: "Analyze this document",
            files: [.init(id: "1", name: "Report.pdf", type: .pdf, preview: .none)],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: false),
            testName: "with_one_file"
        ),
        TestCase(
            initialText: "Analyze this document",
            files: [.init(id: "1", name: "Report.pdf", type: .pdf, preview: .none)],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: false),
            testName: "with_one_file_ghost_mode_web_search"
        ),
        // Two files
        TestCase(
            initialText: "Compare these documents",
            files: [
                .init(id: "1", name: "Contract_v1.pdf", type: .pdf, preview: .none),
                .init(id: "2", name: "Budget.xls", type: .xls, preview: .none),
            ],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "with_two_files"
        ),
        TestCase(
            initialText: "Compare these documents",
            files: [
                .init(id: "1", name: "Contract_v1.pdf", type: .pdf, preview: .none),
                .init(id: "2", name: "Budget.xls", type: .xls, preview: .none),
            ],
            model: .auto,
            isCreateImageEnabled: false,
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "with_two_files_ghost_mode"
        ),
        // Many files
        TestCase(
            initialText: "Process all these files",
            files: [
                .init(id: "1", name: "Report.pdf", type: .pdf, preview: .portraitImage),
                .init(id: "2", name: "Data.xls", type: .xls, preview: .none),
                .init(id: "3", name: "Slides.ppt", type: .ppt, preview: .none),
                .init(id: "4", name: "Image.jpg", type: .image, preview: .landscapeImage),
                .init(id: "5", name: "Video.mp4", type: .video, preview: .none),
            ],
            model: .fast,
            isCreateImageEnabled: false,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: false, isModelSelectionEnabled: true),
            testName: "with_many_files"
        ),
        TestCase(
            initialText: "Process all these files",
            files: [
                .init(id: "1", name: "Report.pdf", type: .pdf, preview: .portraitImage),
                .init(id: "2", name: "Data.xls", type: .xls, preview: .none),
                .init(id: "4", name: "Image.jpg", type: .image, preview: .landscapeImage),
                .init(id: "3", name: "Slides.ppt", type: .ppt, preview: .none),
                .init(id: "5", name: "Video.mp4", type: .video, preview: .none),
            ],
            model: .fast,
            isCreateImageEnabled: false,
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            areButtonsDisabled: false,
            actionButton: .send,
            featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true),
            testName: "with_many_files_ghost_mode_web_search"
        ),
    ]

    @Test(arguments: idleEmptyComposer + shortPrompt + longPrompt + readyToSend + sending + withFiles)
    @MainActor
    func composerView(testCase: TestCase) {
        assertSnapshotsOnEdgeDevices(
            of: sut(testCase: testCase),
            drawHierarchyInKeyWindow: true,
            testName: testCase.testName
        )
    }

    // MARK: - Private

    private func sut(testCase: TestCase) -> some View {
        VStack {
            Spacer()
            ComposerView(
                text: .constant(testCase.initialText),
                files: testCase.files,
                model: testCase.model,
                isCreateImageEnabled: testCase.isCreateImageEnabled,
                isGhostModeEnabled: testCase.isGhostModeEnabled,
                isWebSearchEnabled: testCase.isWebSearchEnabled,
                areButtonsDisabled: testCase.areButtonsDisabled,
                actionButton: testCase.actionButton,
                action: { _ in }
            )
            .environment(\.featureFlags, testCase.featureFlags)
        }
    }
}

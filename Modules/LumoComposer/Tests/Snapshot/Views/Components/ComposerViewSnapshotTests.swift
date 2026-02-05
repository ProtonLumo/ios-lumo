import SnapshotTesting
import SwiftUI
import Testing

@testable import LumoComposer

@MainActor
struct ComposerViewSnapshotTests {
    struct TestCase {
        let initialText: String
        let isGhostModeEnabled: Bool
        let isWebSearchEnabled: Bool
        let actionButton: ComposerView.ActionButtonState
        let testName: String
    }

    /// Idle state - empty composer
    static let idleEmptyComposer: [TestCase] = [
        TestCase(
            initialText: "",
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            actionButton: .none,
            testName: "idle_empty"
        ),
        TestCase(
            initialText: "",
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            actionButton: .none,
            testName: "idle_empty_web_search"
        ),
        TestCase(
            initialText: "",
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            actionButton: .none,
            testName: "idle_empty_ghost_mode"
        ),
        TestCase(
            initialText: "",
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            actionButton: .none,
            testName: "idle_empty_ghost_mode_web_search"
        ),
    ]

    /// Short prompt
    static let shortPrompt: [TestCase] = [
        TestCase(
            initialText: "What is AI?",
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            actionButton: .send,
            testName: "short_prompt_web_search"
        ),
        TestCase(
            initialText: "Explain quantum physics",
            isGhostModeEnabled: true,
            isWebSearchEnabled: false,
            actionButton: .send,
            testName: "short_prompt_ghost_mode"
        ),
    ]

    /// Long prompt
    static let longPrompt: [TestCase] = [
        TestCase(
            initialText:
                "Can you help me understand the differences between supervised and unsupervised learning? I'm particularly interested in real-world examples and how these concepts apply to modern AI systems.",
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            actionButton: .send,
            testName: "long_prompt_web_search"
        ),
        TestCase(
            initialText:
                "Explain quantum computing in simple terms. What are qubits, how do they differ from classical bits, and what are the main challenges in building practical quantum computers?",
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            actionButton: .send,
            testName: "long_prompt_ghost_mode_web_search"
        ),
    ]

    /// Send state - ready to send
    static let readyToSend: [TestCase] = [
        TestCase(
            initialText: "Tell me a story",
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            actionButton: .send,
            testName: "send_state_ready"
        ),
        TestCase(
            initialText: "Search for latest news",
            isGhostModeEnabled: false,
            isWebSearchEnabled: true,
            actionButton: .send,
            testName: "send_state_ready_web_search"
        ),
    ]

    /// Sending state
    static let sending: [TestCase] = [
        TestCase(
            initialText: "",
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            actionButton: .stop,
            testName: "sending_state"
        ),
        TestCase(
            initialText: "",
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            actionButton: .stop,
            testName: "sending_state_ghost_mode_web_search"
        ),
    ]

    @Test(arguments: idleEmptyComposer + shortPrompt + longPrompt + readyToSend + sending)
    func composerView(testCase: TestCase) {
        assertSnapshotsOnEdgeDevices(of: sut(testCase: testCase), testName: testCase.testName)
    }

    // MARK: - Private

    private func sut(testCase: TestCase) -> some View {
        VStack {
            Spacer()
            ComposerView(
                text: .constant(testCase.initialText),
                isGhostModeEnabled: testCase.isGhostModeEnabled,
                isWebSearchEnabled: testCase.isWebSearchEnabled,
                actionButton: testCase.actionButton,
                action: { _ in }
            )
        }
    }
}

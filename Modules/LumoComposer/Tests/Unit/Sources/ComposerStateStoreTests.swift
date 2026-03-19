import Combine
import Difference
import ProtonUIFoundations
import Testing
import UIKit
import UniformTypeIdentifiers
import WebKit

@testable import LumoComposer

@MainActor
final class ComposerStateStoreTests {
    let webViewSpy = WKWebViewSpy()
    let webBridge = WebComposerBridge()
    let toastStateStore = ToastStateStore(initialState: .initial)
    lazy var sut = ComposerStateStore(initialState: initialState, webBridge: webBridge, toastStateStore: toastStateStore)

    var initialState = ComposerViewState.initial
    var cancellables: Set<AnyCancellable> = []

    // MARK: - .webViewReadyChanged action

    @Test
    func webViewReadyChanged_UpdatesStateCorrectly() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        expectDiff(stateChanges, [initialState])

        await sut.send(action: .webViewReadyChanged(true))

        expectDiff(
            stateChanges,
            [
                initialState,
                initialState.copy(\.isWebViewReady, to: true),
            ]
        )
    }

    // MARK: - .taskStarted action

    @Test
    func taskStartedAction_StartsObservingStateUpdates() async {
        webBridge.attach(to: webViewSpy)

        #expect(sut.state.webState.mode == .idle)

        await sut.send(action: .taskStarted)

        simulateWebStateChange(
            lumoMode: "Working",
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isVisible: true,
            showTsAndCs: false,
            files: []
        )

        try? await Task.sleep(for: .milliseconds(50))

        #expect(sut.state.webState.mode == .working)
    }

    @Test
    func onDisappearAction_CancelsObservation() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)

        await sut.send(action: .onDisappear)

        simulateWebStateChange(
            lumoMode: "Working",
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isVisible: true,
            showTsAndCs: false,
            files: []
        )

        await Task.yield()

        #expect(sut.state.webState.mode == .idle)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - Web Error observation

    @Test
    func taskStartedAction_StartsObservingErrorUpdates() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)

        simulateWebError(.generationError)

        try? await Task.sleep(for: .milliseconds(50))

        #expect(toastStateStore.state.toasts == [.webComposerError(.generationError)])
    }

    @Test
    func taskStartedAction_ErrorUpdates_EachErrorCaseShowsCorrectToast() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)

        let allCases: [WebComposerError] = [
            .unknown, .streamDisconnected, .generationError,
            .highDemand, .generationRejected, .harmfulContent,
            .tierLimit, .duplicateFile,
        ]

        for error in allCases {
            simulateWebError(error)
        }

        try? await Task.sleep(for: .milliseconds(50))

        #expect(Array(toastStateStore.state.toasts) == allCases.map(Toast.webComposerError))
    }

    @Test
    func onDisappearAction_CancelsErrorObservation() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .onDisappear)

        simulateWebError(.generationError)

        await Task.yield()

        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .textChanged action

    @Test
    func textChangedAction_ItUpdatesStateCorrectly() async {
        #expect(sut.state == initialState)

        await sut.send(action: .textChanged("Where Apple Park is located?"))

        #expect(sut.state == initialState.copy(\.currentText, to: "Where Apple Park is located?"))
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .sendPrompt action

    @Test
    func sendPromptAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        await sut.send(action: .textChanged("Tell me something about AI"))

        await sut.send(action: .sendPromptTapped)

        expectDiff(
            stateChanges,
            [
                initialState,
                initialState.copy(\.currentText, to: "Tell me something about AI"),
                initialState.copy(\.isProcessing, to: true),
                initialState.copy(\.currentText, to: "Tell me something about AI"),
            ]
        )
        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData))
    func sendPromptAction_WhenWebViewIsAttached_UpdatesStateCorrectly() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        webBridge.attach(to: webViewSpy)

        #expect(webBridge.webView === webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .textChanged("How to make proper neapolitan pizza?"))

        await sut.send(action: .sendPromptTapped)

        let javaScript = """
            window.nativeComposerApi?.sendPrompt('\(UUID.testData.uuidString)', 'How to make proper neapolitan pizza?');
            """

        simulateWebStateChange(
            lumoMode: "Working",
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isVisible: true,
            showTsAndCs: true,
            files: []
        )

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javaScript,
                    frame: .none,
                    contentWorld: .page
                )
        )

        simulateWebStateChange(
            lumoMode: "Idle",
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isVisible: true,
            showTsAndCs: true,
            files: []
        )

        try? await Task.sleep(for: .milliseconds(50))

        expectDiff(
            stateChanges,
            [
                initialState,
                initialState.copy(\.currentText, to: "How to make proper neapolitan pizza?"),
                initialState.copy(\.isProcessing, to: true),
                initialState,
                initialState.copy(
                    \.webState,
                    to: .init(
                        mode: .working,
                        model: .auto,
                        isGhostModeEnabled: false,
                        isWebSearchEnabled: false,
                        isCreateImageEnabled: false,
                        isVisible: true,
                        showTermsAndPrivacy: true,
                        attachedFiles: [],
                        featureFlags: .initial,
                        isFreeUser: true
                    )
                ),
                initialState,
            ]
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func sendPromptAction_WhenWebViewIsAttachedButJavaScriptEvaluationFails_ItReturnsError() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        webBridge.attach(to: webViewSpy)

        #expect(webBridge.webView === webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .textChanged("Tell me a story"))

        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .sendPromptTapped)

        expectDiff(
            stateChanges,
            [
                initialState,
                initialState.copy(\.currentText, to: "Tell me a story"),
                initialState.copy(\.isProcessing, to: true),
                initialState.copy(\.currentText, to: "Tell me a story"),
            ]
        )
        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - .sendPrompt action - Text Escaping

    struct TextEscapingTestCase {
        let input: String
        let expectedOutput: String
        let comment: Comment
    }

    @Test(
        .stubbedUUID(.testData),
        arguments: [
            // Test 1: Double quotes
            TextEscapingTestCase(
                input: "Say \"hello\" to me",
                expectedOutput: "Say \\\"hello\\\" to me",
                comment: "Double quotes should be escaped as \\\" in JavaScript string"
            ),
            // Test 2: Single quotes (must be escaped in single-quoted strings)
            TextEscapingTestCase(
                input: "It's a nice day",
                expectedOutput: "It\\'s a nice day",
                comment: "Single quotes should be escaped as \\' inside single-quoted strings"
            ),
            // Test 3: Newlines
            TextEscapingTestCase(
                input: "Line 1\nLine 2\nLine 3",
                expectedOutput: "Line 1\\nLine 2\\nLine 3",
                comment: "Newlines should be escaped as \\n in JavaScript string"
            ),
            // Test 4: Backslashes
            TextEscapingTestCase(
                input: "Path: C:\\Users\\test",
                expectedOutput: "Path: C:\\\\Users\\\\test",
                comment: "Backslashes should be escaped as \\\\ in JavaScript string"
            ),
            // Test 5: Carriage returns
            TextEscapingTestCase(
                input: "Line 1\r\nLine 2",
                expectedOutput: "Line 1\\r\\nLine 2",
                comment: "Carriage returns should be escaped as \\r in JavaScript string"
            ),
            // Test 6: All special characters combined
            TextEscapingTestCase(
                input: "Say \"hello\"\nIt's nice\nPath: C:\\test",
                expectedOutput: "Say \\\"hello\\\"\\nIt\\'s nice\\nPath: C:\\\\test",
                comment: "All special characters should be properly escaped when combined"
            ),
            // Test 7: Code injection attempt (SECURITY)
            TextEscapingTestCase(
                input: "\"); alert('hacked'); (\"",
                expectedOutput: "\\\"); alert(\\'hacked\\'); (\\\"",
                comment: "Injection attempts should be safely escaped to prevent code execution"
            ),
            // Test 8: Unicode Line and Paragraph Separators (JavaScript edge case)
            TextEscapingTestCase(
                input: "Line 1\u{2028}Line 2\u{2029}Line 3",
                expectedOutput: "Line 1\\u2028Line 2\\u2029Line 3",
                comment: "Unicode line/paragraph separators (U+2028, U+2029) must be escaped to prevent breaking JavaScript"
            ),
        ]
    )
    func sendPromptAction_TextEscaping_EscapesTextCorrectly(testCase: TextEscapingTestCase) async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .textChanged(testCase.input))
        await sut.send(action: .sendPromptTapped)

        let javaScript = "window.nativeComposerApi?.sendPrompt('\(UUID.testData.uuidString)', '\(testCase.expectedOutput)');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javaScript,
                    frame: .none,
                    contentWorld: .page
                ),
            testCase.comment
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .stopResponse action

    @Test
    func stopResponseAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        await sut.send(action: .stopResponseTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData2))
    func stopResponseAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .stopResponseTapped)

        let javaScript = "window.nativeComposerApi?.abortPrompt('\(UUID.testData2.uuidString)');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javaScript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func stopResponseAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .stopResponseTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - .previewAttachment action

    @Test
    func previewAttachmentAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        await sut.send(action: .previewAttachmentTapped(id: "attachment-123"))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData))
    func previewAttachmentAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .previewAttachmentTapped(id: "attachment-456"))

        let javascript = "window.nativeComposerApi?.previewFile('\(UUID.testData.uuidString)', 'attachment-456');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func previewAttachmentAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .previewAttachmentTapped(id: "attachment-789"))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - .removeAttachment action

    @Test
    func removeAttachmentAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        await sut.send(action: .removeAttachmentTapped(id: "attachment-123"))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData2))
    func removeAttachmentAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .removeAttachmentTapped(id: "attachment-789"))

        let javascript = "window.nativeComposerApi?.removeFileEvent('\(UUID.testData2.uuidString)', 'attachment-789');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func removeAttachmentAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)

        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .removeAttachmentTapped(id: "attachment-789"))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - .startRecording action

    @Test
    func startRecordingAction_DoesNothing() async {
        // FIXME: Implement when UI is migrated from main target
        await sut.send(action: .startRecordingTapped)
    }

    // MARK: - .showSheet action

    @Test
    func showSheetAction_Tools_SetsActiveSheet() async {
        await sut.send(action: .showSheet(.tools))

        #expect(sut.state.activeSheet == .tools)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func showSheetAction_ModelSelection_SetsActiveSheet() async {
        await sut.send(action: .showSheet(.modelSelection))

        #expect(sut.state.activeSheet == .modelSelection)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .dismissActiveSheet action

    @Test
    func dismissActiveSheetAction_ClearsActiveSheet() async {
        await sut.send(action: .showSheet(.tools))
        await sut.send(action: .dismissActiveSheet)

        #expect(sut.state.activeSheet == nil)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .toolsSheetAction action

    @Test(.stubbedUUID(.testData3))
    func toolsSheetAction_CreateImageTapped_DismissesSheetAndTogglesCreateImage() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .showSheet(.tools))
        await sut.send(action: .toolsSheetAction(.createImageTapped))

        let javascript = "window.nativeComposerApi?.toggleCreateImage('\(UUID.testData3.uuidString)');"

        #expect(sut.state.activeSheet == nil)
        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(javaScript: javascript, frame: .none, contentWorld: .page)
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test(.stubbedUUID(.testData))
    func toolsSheetAction_WebSearchToggled_DoesNotDismissSheet() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .showSheet(.tools))
        await sut.send(action: .toolsSheetAction(.webSearchToggled))

        let javascript = "window.nativeComposerApi?.toggleWebSearch('\(UUID.testData.uuidString)');"

        #expect(sut.state.activeSheet == .tools)
        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(javaScript: javascript, frame: .none, contentWorld: .page)
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func toolsSheetAction_WebSearchToggled_WhenWebViewNotAttached_ShowsErrorToast() async {
        await sut.send(action: .toolsSheetAction(.webSearchToggled))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test
    func toolsSheetAction_WebSearchToggled_WhenJavaScriptEvaluationFails_ShowsErrorToast() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .toolsSheetAction(.webSearchToggled))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test
    func toolsSheetAction_CloseTapped_DismissesSheet() async {
        await sut.send(action: .showSheet(.tools))
        await sut.send(action: .toolsSheetAction(.closeTapped))

        #expect(sut.state.activeSheet == nil)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .modelSelectionSheetAction action

    @Test(.stubbedUUID(.testData2))
    func modelSelectionSheetAction_ModelSelected_DismissesSheet() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .showSheet(.modelSelection))
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.fast)))

        #expect(sut.state.activeSheet == nil)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test(.stubbedUUID(.testData2))
    func modelSelectionSheetAction_ModelSelected_ExecutesCorrectJavaScriptForAutoAndFast() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)

        let javascript: (String) -> String = { mode in
            "window.nativeComposerApi?.changeModelTier('\(UUID.testData2.uuidString)', '\(mode)');"
        }

        await sut.send(action: .showSheet(.modelSelection))
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.auto)))
        #expect(webViewSpy.evaluateJavaScriptCalls.last?.javaScript == javascript("auto"))

        await sut.send(action: .showSheet(.modelSelection))
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.fast)))
        #expect(webViewSpy.evaluateJavaScriptCalls.last?.javaScript == javascript("fast"))

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 2)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test(.stubbedUUID(.testData2))
    func modelSelectionSheetAction_ThinkingSelected_WhenPaidUser_ExecutesCorrectJavaScript() async {
        var cancellables: Set<AnyCancellable> = []
        var freeUserThinkingTappedCount = 0

        initialState = initialState.copy(\.webState, to: .initialPaidUser)

        webBridge.attach(to: webViewSpy)

        sut
            .freeUserThinkingTappedPublisher
            .sink { freeUserThinkingTappedCount += 1 }
            .store(in: &cancellables)

        await sut.send(action: .taskStarted)
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.thinking)))

        let javascript = "window.nativeComposerApi?.changeModelTier('\(UUID.testData2.uuidString)', 'thinking');"
        #expect(webViewSpy.evaluateJavaScriptCalls.last?.javaScript == javascript)
        #expect(toastStateStore.state.toasts.isEmpty)
        #expect(freeUserThinkingTappedCount == 0)
    }

    @Test
    func modelSelectionSheetAction_ThinkingSelected_WhenFreeUser_EmitsFreeUserThinkingTappedEvent() async {
        var cancellables: Set<AnyCancellable> = []
        var freeUserThinkingTappedCount = 0

        sut
            .freeUserThinkingTappedPublisher
            .sink { freeUserThinkingTappedCount += 1 }
            .store(in: &cancellables)

        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.thinking)))

        #expect(freeUserThinkingTappedCount == 1)
    }

    @Test
    func modelSelectionSheetAction_ThinkingSelected_WhenFreeUser_DismissesSheet() async {
        await sut.send(action: .showSheet(.modelSelection))
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.thinking)))

        #expect(sut.state.activeSheet == nil)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func modelSelectionSheetAction_ThinkingSelected_WhenFreeUser_DoesNotCallBridge() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.thinking)))

        #expect(webViewSpy.evaluateJavaScriptCalls.isEmpty)
    }

    @Test
    func modelSelectionSheetAction_ModelSelected_WhenWebViewNotAttached_ShowsErrorToast() async {
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.auto)))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test
    func modelSelectionSheetAction_ModelSelected_WhenJavaScriptEvaluationFails_ShowsErrorToast() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .modelSelectionSheetAction(.modelSelected(.auto)))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test
    func modelSelectionSheetAction_CloseTapped_DismissesSheet() async {
        await sut.send(action: .showSheet(.modelSelection))
        await sut.send(action: .modelSelectionSheetAction(.closeTapped))

        #expect(sut.state.activeSheet == nil)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .uploadFiles action

    @Test
    func uploadFilesAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let files = [FileUploadData(base64: "YmFzZTY0ZGF0YQ==", name: "test.pdf")]

        await sut.send(action: .uploadFilesTapped(files))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData3))
    func uploadFilesAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)

        let files = [
            FileUploadData(base64: "ZGF0YTE=", name: "file1.pdf"),
            FileUploadData(base64: "ZGF0YTI=", name: "file2.png"),
        ]
        await sut.send(action: .uploadFilesTapped(files))

        let javascript = "window.nativeComposerApi?.uploadFiles('\(UUID.testData3.uuidString)', [{ base64: 'ZGF0YTE=', name: 'file1.pdf' }, { base64: 'ZGF0YTI=', name: 'file2.png' }]);"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func uploadFilesAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)

        let files = [FileUploadData(base64: "data", name: "test.pdf")]
        await sut.send(action: .uploadFilesTapped(files))

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - .openProtonDrive action

    @Test
    func openProtonDriveAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        await sut.send(action: .openProtonDriveTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData))
    func openProtonDriveAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .openProtonDriveTapped)

        let javascript = "window.nativeComposerApi?.openProtonDrive('\(UUID.testData.uuidString)');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func openProtonDriveAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .openProtonDriveTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - .openSketch action

    @Test
    func openSketchAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        await sut.send(action: .openSketchTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData2))
    func openSketchAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .openSketchTapped)

        let javascript = "window.nativeComposerApi?.openSketch('\(UUID.testData2.uuidString)');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func openSketchAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .openSketchTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - .toggleCreateImage action

    @Test
    func toggleCreateImageAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        await sut.send(action: .toggleCreateImageTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    @Test(.stubbedUUID(.testData3))
    func toggleCreateImageAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .toggleCreateImageTapped)

        let javascript = "window.nativeComposerApi?.toggleCreateImage('\(UUID.testData3.uuidString)');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func toggleCreateImageAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        await sut.send(action: .taskStarted)
        await sut.send(action: .toggleCreateImageTapped)

        #expect(toastStateStore.state.toasts == [.bridgeError])
    }

    // MARK: - Web State observation

    @Test
    func webStateChanges_UpdatesStateCorrectly() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        webBridge.attach(to: webViewSpy)

        expectDiff(stateChanges, [initialState])

        await sut.send(action: .taskStarted)

        simulateWebStateChange(
            lumoMode: "Working",
            isGhostModeEnabled: true,
            isWebSearchEnabled: true,
            isVisible: false,
            showTsAndCs: false,
            files: [
                .init(id: "<id_1>", name: "document.pdf", type: .pdf, preview: .none)
            ]
        )

        try? await Task.sleep(for: .milliseconds(50))

        expectDiff(
            stateChanges,
            [
                initialState,
                initialState
                    .copy(
                        \.webState,
                        to: WebComposerState(
                            mode: .working,
                            model: .auto,
                            isGhostModeEnabled: true,
                            isWebSearchEnabled: true,
                            isCreateImageEnabled: false,
                            isVisible: false,
                            showTermsAndPrivacy: false,
                            attachedFiles: [
                                File(id: "<id_1>", name: "document.pdf", type: .pdf, preview: .none)
                            ],
                            featureFlags: .initial,
                            isFreeUser: true
                        )
                    ),
            ]
        )
    }

    // MARK: - .showPicker action

    @Test
    func showPickerAction_Files_SetsActivePicker() async {
        await sut.send(action: .showPicker(.files))

        #expect(sut.state.activeSystemPicker == .files)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func showPickerAction_Photos_SetsActivePicker() async {
        await sut.send(action: .showPicker(.photos))

        #expect(sut.state.activeSystemPicker == .photos)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func showPickerAction_Camera_SetsActivePicker() async {
        await sut.send(action: .showPicker(.camera))

        #expect(sut.state.activeSystemPicker == .camera)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .dismissActivePicker action

    @Test
    func dismissActivePickerAction_ClearsActivePicker() async {
        await sut.send(action: .showPicker(.camera))

        await sut.send(action: .dismissActivePicker)

        #expect(sut.state.activeSystemPicker == nil)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - .filesPicked action

    @Test(.stubbedUUID(.testData3))
    func filesPickedAction_Success_UploadsFileWithCorrectDataAndName() async {
        let fileData = Data("hello".utf8)
        let sut = ComposerStateStore(
            initialState: initialState,
            webBridge: webBridge,
            toastStateStore: toastStateStore,
            fileLoader: { _ in fileData }
        )
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .filesPicked(.success(URL(string: "file:///Documents/report.pdf")!)))

        let javascript = "window.nativeComposerApi?.uploadFiles('\(UUID.testData3.uuidString)', [{ base64: '\(fileData.base64EncodedString())', name: 'report.pdf' }]);"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(webViewSpy.evaluateJavaScriptCalls.last == .init(javaScript: javascript, frame: .none, contentWorld: .page))
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func filesPickedAction_Failure_ShowsErrorToast() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .filesPicked(.failure(CocoaError(.fileNoSuchFile))))

        #expect(webViewSpy.evaluateJavaScriptCalls.isEmpty)
        #expect(toastStateStore.state.toasts == [.genericError])
    }

    @Test
    func filesPickedAction_WhenLoaderThrows_ShowsErrorToast() async {
        let sut = ComposerStateStore(
            initialState: initialState,
            webBridge: webBridge,
            toastStateStore: toastStateStore,
            fileLoader: { _ in throw CocoaError(.fileReadNoPermission) }
        )
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .filesPicked(.success(URL(string: "file:///Documents/report.pdf")!)))

        #expect(webViewSpy.evaluateJavaScriptCalls.isEmpty)
        #expect(toastStateStore.state.toasts == [.genericError])
    }

    // MARK: - .photoPicked action

    @Test(.stubbedUUID(.testData))
    func photoPickedAction_WhenDataLoaded_UploadsPhotoWithCorrectData() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)

        let photoData = Data("photo-bytes".utf8)
        let item = TestPhotosItem(stubbedResult: .success(photoData))

        await sut.send(action: .photoPicked(item))

        let expectedName = "\(UUID.testData.uuidString).jpg"
        let javascript = "window.nativeComposerApi?.uploadFiles('\(UUID.testData.uuidString)', [{ base64: '\(photoData.base64EncodedString())', name: '\(expectedName)' }]);"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(webViewSpy.evaluateJavaScriptCalls.last == .init(javaScript: javascript, frame: .none, contentWorld: .page))
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func photoPickedAction_WhenDataIsNil_DoesNothing() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .photoPicked(TestPhotosItem(stubbedResult: .success(nil))))

        #expect(webViewSpy.evaluateJavaScriptCalls.isEmpty)
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    @Test
    func photoPickedAction_WhenLoadThrows_ShowsErrorToast() async {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)
        await sut.send(action: .photoPicked(TestPhotosItem(stubbedResult: .failure(CocoaError(.coderInvalidValue)))))

        #expect(webViewSpy.evaluateJavaScriptCalls.isEmpty)
        #expect(toastStateStore.state.toasts == [.genericError])
    }

    // MARK: - .imageCaptured action

    @Test(.stubbedUUID(.testData2))
    func imageCapturedAction_UploadsImageWithJpegDataAndUUIDName() async throws {
        webBridge.attach(to: webViewSpy)

        await sut.send(action: .taskStarted)

        let imageData = try #require(Data(base64Encoded: .portraitImage))
        let image = try #require(UIImage(data: imageData))

        await sut.send(action: .imageCaptured(image))

        let expectedBase64 = image.jpegData(compressionQuality: 0.7)!.base64EncodedString()
        let expectedName = "\(UUID.testData2.uuidString).jpg"
        let javascript = "window.nativeComposerApi?.uploadFiles('\(UUID.testData2.uuidString)', [{ base64: '\(expectedBase64)', name: '\(expectedName)' }]);"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(webViewSpy.evaluateJavaScriptCalls.last == .init(javaScript: javascript, frame: .none, contentWorld: .page))
        #expect(toastStateStore.state.toasts.isEmpty)
    }

    // MARK: - Private

    private func observeStateChanges(_ stateChange: @escaping (ComposerViewState) -> Void) {
        sut.$state
            .sink { state in stateChange(state) }
            .store(in: &cancellables)
    }

    private func simulateWebError(_ error: WebComposerError) {
        webBridge.handleError(["status": "error", "error": error.rawValue])
    }

    private func simulateWebStateChange(
        lumoMode: String,
        isGhostModeEnabled: Bool,
        isWebSearchEnabled: Bool,
        isVisible: Bool,
        showTsAndCs: Bool,
        files: [File]
    ) {
        let attachedFiles: [[String: Any]] = files.map { file in
            var fileDict: [String: Any] = [:]
            fileDict["id"] = file.id
            fileDict["name"] = file.name
            fileDict["type"] = file.type.rawValue
            return fileDict
        }
        let state: [String: Any] = [
            "lumoMode": lumoMode,
            "modelTier": "auto",
            "isGhostModeEnabled": isGhostModeEnabled,
            "isWebSearchEnabled": isWebSearchEnabled,
            "isCreateImageEnabled": false,
            "isVisible": isVisible,
            "showTsAndCs": showTsAndCs,
            "attachedFiles": attachedFiles,
            "featureFlags": [
                "isImageGenEnabled": false,
                "isModelSelectionEnabled": false,
            ],
            "isFreeUser": true,
        ]

        webBridge.handleStateChange(state: state)
    }
}

private extension Toast {
    static let bridgeError = Toast.error(message: WebComposerBridgeError.webViewNotAttached.localizedDescription)
    static let genericError = Toast.error(message: WebComposerError.unknown.localizedDescription)
    static func webComposerError(_ error: WebComposerError) -> Toast {
        .error(message: error.localizedDescription)
    }
}

private extension UUID {
    static let testData = UUID(uuidString: "F82958B5-6EB1-42A7-BC2B-A7F6617E1EF7")!
    static let testData2 = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    static let testData3 = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
}

private extension WebComposerState {
    static var initialPaidUser: Self {
        .init(
            mode: .idle,
            model: .auto,
            isGhostModeEnabled: false,
            isWebSearchEnabled: false,
            isCreateImageEnabled: false,
            isVisible: true,
            showTermsAndPrivacy: true,
            attachedFiles: [],
            featureFlags: .initial,
            isFreeUser: false
        )
    }
}

private struct TestPhotosItem: PhotosItemLoading {
    let stubbedResult: Result<Data?, any Error>

    // MARK: - PhotosItem

    var itemIdentifier: String? = nil
    var supportedContentTypes: [UTType] = []

    // MARK: - PhotosItemLoading

    func loadTransferableData() async throws -> Data? {
        try stubbedResult.get()
    }
}

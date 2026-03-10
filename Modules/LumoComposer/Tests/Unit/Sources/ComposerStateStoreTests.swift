import Combine
import Difference
import Testing
import WebKit

@testable import LumoComposer

@MainActor
final class ComposerStateStoreTests {
    let webViewSpy = WKWebViewSpy()
    let webBridge = WebComposerBridge()
    lazy var sut = ComposerStateStore(initialState: initialState, webBridge: webBridge)

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

        let effect = await sut.send(action: .webViewReadyChanged(true))

        #expect(effect == .none)
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

        let effect = await sut.send(action: .taskStarted)

        #expect(effect == .none)

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

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .onDisappear)

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
        #expect(effect == .none)
    }

    // MARK: - .textChanged action

    @Test
    func textChangedAction_ItUpdatesStateCorrectly() async {
        #expect(sut.state == initialState)

        let effect = await sut.send(action: .textChanged("Where Apple Park is located?"))

        #expect(sut.state == initialState.copy(\.currentText, to: "Where Apple Park is located?"))
        #expect(effect == .none)
    }

    // MARK: - .sendPrompt action

    @Test
    func sendPromptAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        _ = await sut.send(action: .textChanged("Tell me something about AI"))

        let effect = await sut.send(action: .sendPromptTapped)

        expectDiff(
            stateChanges,
            [
                initialState,
                initialState.copy(\.currentText, to: "Tell me something about AI"),
                initialState.copy(\.isProcessing, to: true),
                initialState.copy(\.currentText, to: "Tell me something about AI"),
            ]
        )
        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "212A909D-2D5C-4891-8717-685D27C6A4EE")!))
    func sendPromptAction_WhenWebViewIsAttached_UpdatesStateCorrectly() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        webBridge.attach(to: webViewSpy)

        #expect(webBridge.webView === webViewSpy)

        _ = await sut.send(action: .taskStarted)
        _ = await sut.send(action: .textChanged("How to make proper neapolitan pizza?"))

        let effect = await sut.send(action: .sendPromptTapped)

        let javaScript = """
            window.nativeComposerApi?.sendPrompt('212A909D-2D5C-4891-8717-685D27C6A4EE', 'How to make proper neapolitan pizza?');
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
                        featureFlags: .init(isImageGenEnabled: false, isModelSelectionEnabled: false)
                    )
                ),
                initialState,
            ]
        )
        #expect(effect == .none)
    }

    @Test
    func sendPromptAction_WhenWebViewIsAttachedButJavaScriptEvaluationFails_ItReturnsError() async {
        var stateChanges: [ComposerViewState] = []

        observeStateChanges { state in
            stateChanges.append(state)
        }

        webBridge.attach(to: webViewSpy)

        #expect(webBridge.webView === webViewSpy)

        _ = await sut.send(action: .taskStarted)
        _ = await sut.send(action: .textChanged("Tell me a story"))

        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        let effect = await sut.send(action: .sendPromptTapped)

        expectDiff(
            stateChanges,
            [
                initialState,
                initialState.copy(\.currentText, to: "Tell me a story"),
                initialState.copy(\.isProcessing, to: true),
                initialState.copy(\.currentText, to: "Tell me a story"),
            ]
        )
        #expect(effect == .error(.evaluatingJSFailed(.sendPrompt("Tell me a story"))))
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

        _ = await sut.send(action: .textChanged(testCase.input))
        let effect = await sut.send(action: .sendPromptTapped)

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
        #expect(effect == .none)
    }

    // MARK: - .stopResponse action

    @Test
    func stopResponseAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .stopResponseTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!))
    func stopResponseAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)
        let effect = await sut.send(action: .stopResponseTapped)

        let javaScript = "window.nativeComposerApi?.abortPrompt('A1B2C3D4-E5F6-7890-ABCD-EF1234567890');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javaScript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func stopResponseAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .stopResponseTapped)

        #expect(effect == .error(.evaluatingJSFailed(.stopResponse)))
    }

    // MARK: - .toggleWebSearch action

    @Test
    func toggleWebSearchAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .toggleWebSearchTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!))
    func toggleWebSearchAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .toggleWebSearchTapped)

        let javascript = "window.nativeComposerApi?.toggleWebSearch('C3D4E5F6-A7B8-9012-CDEF-123456789012');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func toggleWebSearchAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .toggleWebSearchTapped)

        #expect(effect == .error(.evaluatingJSFailed(.toggleWebSearch)))
    }

    // MARK: - .previewAttachment action

    @Test
    func previewAttachmentAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .previewAttachmentTapped(id: "attachment-123"))

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "D4E5F6A7-B8C9-0123-DEF1-234567890123")!))
    func previewAttachmentAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .previewAttachmentTapped(id: "attachment-456"))

        let javascript = "window.nativeComposerApi?.previewFile('D4E5F6A7-B8C9-0123-DEF1-234567890123', 'attachment-456');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func previewAttachmentAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .previewAttachmentTapped(id: "attachment-789"))

        #expect(effect == .error(.evaluatingJSFailed(.previewAttachment(id: "attachment-789"))))
    }

    // MARK: - .removeAttachment action

    @Test
    func removeAttachmentAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .removeAttachmentTapped(id: "attachment-123"))

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "E5F6A7B8-C9D0-1234-EF12-345678901234")!))
    func removeAttachmentAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .removeAttachmentTapped(id: "attachment-789"))

        let javascript = "window.nativeComposerApi?.removeFileEvent('E5F6A7B8-C9D0-1234-EF12-345678901234', 'attachment-789');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func removeAttachmentAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)

        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .removeAttachmentTapped(id: "attachment-789"))

        #expect(effect == .error(.evaluatingJSFailed(.removeAttachment(id: "attachment-789"))))
    }

    // MARK: - .startRecording action

    @Test
    func startRecordingAction_ReturnsNoneEffect() async {
        // FIXME: Implement when UI is migrated from main target
        let effect = await sut.send(action: .startRecordingTapped)

        #expect(effect == .none)
    }

    // MARK: - .showSheet action

    @Test
    func showSheetAction_Tools_SetsActiveSheet() async {
        let effect = await sut.send(action: .showSheet(.tools))

        #expect(sut.state.activeSheet == .tools)
        #expect(effect == .none)
    }

    @Test
    func showSheetAction_ModelSelection_SetsActiveSheet() async {
        let effect = await sut.send(action: .showSheet(.modelSelection))

        #expect(sut.state.activeSheet == .modelSelection)
        #expect(effect == .none)
    }

    // MARK: - .dismissActiveSheet action

    @Test
    func dismissActiveSheetAction_ClearsActiveSheet() async {
        _ = await sut.send(action: .showSheet(.tools))

        let effect = await sut.send(action: .dismissActiveSheet)

        #expect(sut.state.activeSheet == nil)
        #expect(effect == .none)
    }

    // MARK: - .toolsSheetAction action

    @Test(.stubbedUUID(UUID(uuidString: "F2A3B4C5-D6E7-8901-F678-012345678901")!))
    func toolsSheetAction_CreateImageTapped_DismissesSheetAndTogglesCreateImage() async {
        webBridge.attach(to: webViewSpy)
        _ = await sut.send(action: .taskStarted)
        _ = await sut.send(action: .showSheet(.tools))

        let effect = await sut.send(action: .toolsSheetAction(.createImageTapped))

        let javascript = "window.nativeComposerApi?.toggleCreateImage('F2A3B4C5-D6E7-8901-F678-012345678901');"

        #expect(sut.state.activeSheet == nil)
        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(javaScript: javascript, frame: .none, contentWorld: .page)
        )
        #expect(effect == .none)
    }

    @Test(.stubbedUUID(UUID(uuidString: "A3B4C5D6-E7F8-9012-A789-123456789012")!))
    func toolsSheetAction_WebSearchToggled_DoesNotDismissSheet() async {
        webBridge.attach(to: webViewSpy)
        _ = await sut.send(action: .taskStarted)
        _ = await sut.send(action: .showSheet(.tools))

        let effect = await sut.send(action: .toolsSheetAction(.webSearchToggled))

        let javascript = "window.nativeComposerApi?.toggleWebSearch('A3B4C5D6-E7F8-9012-A789-123456789012');"

        #expect(sut.state.activeSheet == .tools)
        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(javaScript: javascript, frame: .none, contentWorld: .page)
        )
        #expect(effect == .none)
    }

    @Test
    func toolsSheetAction_CloseTapped_DismissesSheet() async {
        _ = await sut.send(action: .showSheet(.tools))

        let effect = await sut.send(action: .toolsSheetAction(.closeTapped))

        #expect(sut.state.activeSheet == nil)
        #expect(effect == .none)
    }

    // MARK: - .modelSelectionSheetAction action

    @Test(.stubbedUUID(UUID(uuidString: "B4C5D6E7-F8A9-0123-B890-234567890123")!))
    func modelSelectionSheetAction_ModelSelected_DismissesSheetAndChangesModel() async {
        webBridge.attach(to: webViewSpy)
        _ = await sut.send(action: .taskStarted)
        _ = await sut.send(action: .showSheet(.modelSelection))

        let effect = await sut.send(action: .modelSelectionSheetAction(.modelSelected(.fast)))

        let javascript = "window.nativeComposerApi?.changeModel('B4C5D6E7-F8A9-0123-B890-234567890123', 'Fast');"

        #expect(sut.state.activeSheet == nil)
        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(javaScript: javascript, frame: .none, contentWorld: .page)
        )
        #expect(effect == .none)
    }

    @Test
    func modelSelectionSheetAction_CloseTapped_DismissesSheet() async {
        _ = await sut.send(action: .showSheet(.modelSelection))

        let effect = await sut.send(action: .modelSelectionSheetAction(.closeTapped))

        #expect(sut.state.activeSheet == nil)
        #expect(effect == .none)
    }

    // MARK: - .uploadFiles action

    @Test
    func uploadFilesAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let files = [FileUploadData(base64: "YmFzZTY0ZGF0YQ==", name: "test.pdf")]
        let effect = await sut.send(action: .uploadFilesTapped(files))

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "F6A7B8C9-D0E1-2345-F123-456789012345")!))
    func uploadFilesAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let files = [
            FileUploadData(base64: "ZGF0YTE=", name: "file1.pdf"),
            FileUploadData(base64: "ZGF0YTI=", name: "file2.png"),
        ]
        let effect = await sut.send(action: .uploadFilesTapped(files))

        let javascript = "window.nativeComposerApi?.uploadFiles('F6A7B8C9-D0E1-2345-F123-456789012345', [{ base64: 'ZGF0YTE=', name: 'file1.pdf' }, { base64: 'ZGF0YTI=', name: 'file2.png' }]);"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func uploadFilesAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let files = [FileUploadData(base64: "data", name: "test.pdf")]
        let effect = await sut.send(action: .uploadFilesTapped(files))

        #expect(effect == .error(.evaluatingJSFailed(.uploadFiles(files))))
    }

    // MARK: - .openProtonDrive action

    @Test
    func openProtonDriveAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .openProtonDriveTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "A7B8C9D0-E1F2-3456-A123-567890123456")!))
    func openProtonDriveAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .openProtonDriveTapped)

        let javascript = "window.nativeComposerApi?.openProtonDrive('A7B8C9D0-E1F2-3456-A123-567890123456');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func openProtonDriveAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .openProtonDriveTapped)

        #expect(effect == .error(.evaluatingJSFailed(.openProtonDrive)))
    }

    // MARK: - .openSketch action

    @Test
    func openSketchAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .openSketchTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "B8C9D0E1-F2A3-4567-B234-678901234567")!))
    func openSketchAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .openSketchTapped)

        let javascript = "window.nativeComposerApi?.openSketch('B8C9D0E1-F2A3-4567-B234-678901234567');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func openSketchAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .openSketchTapped)

        #expect(effect == .error(.evaluatingJSFailed(.openSketch)))
    }

    // MARK: - .toggleCreateImage action

    @Test
    func toggleCreateImageAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .toggleCreateImageTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "C9D0E1F2-A3B4-5678-C345-789012345678")!))
    func toggleCreateImageAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .toggleCreateImageTapped)

        let javascript = "window.nativeComposerApi?.toggleCreateImage('C9D0E1F2-A3B4-5678-C345-789012345678');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test
    func toggleCreateImageAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .toggleCreateImageTapped)

        #expect(effect == .error(.evaluatingJSFailed(.toggleCreateImage)))
    }

    // MARK: - .changeModel action

    @Test
    func changeModelAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.send(action: .changeModelTapped(.fast))

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "D0E1F2A3-B4C5-6789-D456-890123456789")!))
    func changeModelAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .changeModelTapped(.thinking))

        let javascript = "window.nativeComposerApi?.changeModel('D0E1F2A3-B4C5-6789-D456-890123456789', 'Thinking');"

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )
        #expect(effect == .none)
    }

    @Test(.stubbedUUID(UUID(uuidString: "E1F2A3B4-C5D6-7890-E567-901234567890")!))
    func changeModelAction_ForAllModelTypes_ExecutesCorrectJavaScript() async {
        webBridge.attach(to: webViewSpy)

        _ = await sut.send(action: .taskStarted)

        let javascript: (String) -> String = { mode in
            "window.nativeComposerApi?.changeModel('E1F2A3B4-C5D6-7890-E567-901234567890', '\(mode)');"
        }

        _ = await sut.send(action: .changeModelTapped(.auto))
        #expect(webViewSpy.evaluateJavaScriptCalls.last?.javaScript == javascript("Auto"))

        _ = await sut.send(action: .changeModelTapped(.fast))
        #expect(webViewSpy.evaluateJavaScriptCalls.last?.javaScript == javascript("Fast"))

        _ = await sut.send(action: .changeModelTapped(.thinking))
        #expect(webViewSpy.evaluateJavaScriptCalls.last?.javaScript == javascript("Thinking"))

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 3)
    }

    @Test
    func changeModelAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        _ = await sut.send(action: .taskStarted)

        let effect = await sut.send(action: .changeModelTapped(.auto))

        #expect(effect == .error(.evaluatingJSFailed(.changeModel(.auto))))
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

        let effect = await sut.send(action: .taskStarted)

        #expect(effect == .none)

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
                            featureFlags: .init(isImageGenEnabled: false, isModelSelectionEnabled: false)
                        )
                    ),
            ]
        )
    }

    // MARK: - Private

    private func observeStateChanges(_ stateChange: @escaping (ComposerViewState) -> Void) {
        sut.$state
            .sink { state in stateChange(state) }
            .store(in: &cancellables)
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
            "modelType": "Auto",
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
        ]

        webBridge.handleStateChange(state: state)
    }
}

private extension UUID {
    static let testData = UUID(uuidString: "F82958B5-6EB1-42A7-BC2B-A7F6617E1EF7")!
}

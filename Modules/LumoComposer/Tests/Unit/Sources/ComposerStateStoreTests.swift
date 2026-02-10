import Combine
import Testing
import WebKit

@testable import LumoComposer

@MainActor
final class ComposerStateStoreTests {
    let webViewSpy = WKWebViewSpy()
    let webBridge = WebComposerBridge()
    lazy var sut = ComposerStateStore(initialState: .initial, webBridge: webBridge)

    var initialState = ComposerViewState.initial
    var cancellables: Set<AnyCancellable> = []

    @Test
    func textChangedAction_ItUpdatesStateCorrectly() async {
        #expect(sut.state == initialState)

        let effect = await sut.handle(action: .textChanged(to: "Where Apple Park is located?"))

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

        _ = await sut.handle(action: .textChanged(to: "Tell me something about AI"))

        let effect = await sut.handle(action: .sendPromptTapped)

        #expect(
            stateChanges == [
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

        _ = await sut.handle(action: .textChanged(to: "How to make proper neapolitan pizza?"))

        let effect = await sut.handle(action: .sendPromptTapped)

        let javascript = """
            window.nativeComposerApi?.sendPrompt('212A909D-2D5C-4891-8717-685D27C6A4EE', How to make proper neapolitan pizza?);
            """

        #expect(webViewSpy.evaluateJavaScriptCalls.count == 1)
        #expect(
            webViewSpy.evaluateJavaScriptCalls.last
                == .init(
                    javaScript: javascript,
                    frame: .none,
                    contentWorld: .page
                )
        )

        #expect(
            stateChanges == [
                initialState,
                initialState.copy(\.currentText, to: "How to make proper neapolitan pizza?"),
                initialState.copy(\.isProcessing, to: true),
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

        _ = await sut.handle(action: .textChanged(to: "Tell me a story"))

        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        let effect = await sut.handle(action: .sendPromptTapped)

        #expect(
            stateChanges == [
                initialState,
                initialState.copy(\.currentText, to: "Tell me a story"),
                initialState.copy(\.isProcessing, to: true),
                initialState.copy(\.currentText, to: "Tell me a story"),
            ]
        )
        #expect(effect == .error(.evaluatingJSFailed(.sendPrompt("Tell me a story"))))
    }

    // MARK: - .stopResponse action

    @Test
    func stopResponseAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.handle(action: .stopResponseTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!))
    func stopResponseAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        let effect = await sut.handle(action: .stopResponseTapped)

        let javascript = "window.nativeComposerApi?.abortPrompt('A1B2C3D4-E5F6-7890-ABCD-EF1234567890');"

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
    func stopResponseAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        let effect = await sut.handle(action: .stopResponseTapped)

        #expect(effect == .error(.evaluatingJSFailed(.stopResponse)))
    }

    // MARK: - .openFilePicker action

    @Test
    func openFilePickerAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.handle(action: .openFilePickerTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!))
    func openFilePickerAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        let effect = await sut.handle(action: .openFilePickerTapped)

        let javascript = "window.nativeComposerApi?.onAttachClick('B2C3D4E5-F6A7-8901-BCDE-F12345678901');"

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
    func openFilePickerAction_WhenJavaScriptEvaluationFails_ItReturnsError() async {
        webBridge.attach(to: webViewSpy)
        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        let effect = await sut.handle(action: .openFilePickerTapped)

        #expect(effect == .error(.evaluatingJSFailed(.openFilePicker)))
    }

    // MARK: - .toggleWebSearch action

    @Test
    func toggleWebSearchAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.handle(action: .toggleWebSearchTapped)

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!))
    func toggleWebSearchAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        let effect = await sut.handle(action: .toggleWebSearchTapped)

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

        let effect = await sut.handle(action: .toggleWebSearchTapped)

        #expect(effect == .error(.evaluatingJSFailed(.toggleWebSearch)))
    }

    // MARK: - .previewAttachment action

    @Test
    func previewAttachmentAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.handle(action: .previewAttachmentTapped(id: "attachment-123"))

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "D4E5F6A7-B8C9-0123-DEF1-234567890123")!))
    func previewAttachmentAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        let effect = await sut.handle(action: .previewAttachmentTapped(id: "attachment-456"))

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

        let effect = await sut.handle(action: .previewAttachmentTapped(id: "attachment-789"))

        #expect(effect == .error(.evaluatingJSFailed(.previewAttachment(id: "attachment-789"))))
    }

    // MARK: - .removeAttachment action

    @Test
    func removeAttachmentAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        let effect = await sut.handle(action: .removeAttachmentTapped(id: "attachment-123"))

        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "E5F6A7B8-C9D0-1234-EF12-345678901234")!))
    func removeAttachmentAction_WhenWebViewIsAttached_ExecutesJavaScriptCorrectly() async {
        webBridge.attach(to: webViewSpy)

        let effect = await sut.handle(action: .removeAttachmentTapped(id: "attachment-789"))

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

        let effect = await sut.handle(action: .removeAttachmentTapped(id: "attachment-789"))

        #expect(effect == .error(.evaluatingJSFailed(.removeAttachment(id: "attachment-789"))))
    }

    // MARK: - .startRecording action

    @Test
    func startRecordingAction_ReturnsNoneEffect() async {
        // FIXME: Implement when UI is migrated from main target
        let effect = await sut.handle(action: .startRecordingTapped)

        #expect(effect == .none)
    }

    // MARK: - Private

    private func observeStateChanges(_ stateChange: @escaping (ComposerViewState) -> Void) {
        sut.$state
            .sink { state in stateChange(state) }
            .store(in: &cancellables)
    }
}

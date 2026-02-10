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

        let effect = await sut.handle(action: .textChanged(to: "Tell me something about AI"))

        #expect(sut.state == initialState.copy(\.currentText, to: "Tell me something about AI"))
        #expect(effect == .none)
    }

    // MARK: - .sendPrompt action

    @Test
    func sendPromptAction_WhenWebViewNotAttached_ItReturnsErrorEffect() async {
        var stateChanges: [ComposerViewState] = []

        var cancellables: Set<AnyCancellable> = []

        sut.$state
            .sink { state in stateChanges.append(state) }
            .store(in: &cancellables)

        _ = await sut.handle(action: .textChanged(to: "Tell me something about AI"))

        let effect = await sut.handle(action: .sendPromptTapped)

        let updatedState =
            initialState
            .copy(\.currentText, to: "")
            .copy(\.isProcessing, to: true)

        #expect(
            stateChanges == [
                initialState,
                initialState.copy(\.currentText, to: "Tell me something about AI"),
                updatedState,
                initialState.copy(\.currentText, to: "Tell me something about AI"),
            ]
        )
        #expect(effect == .error(.webViewNotAttached))
    }

    @Test(.stubbedUUID(UUID(uuidString: "212A909D-2D5C-4891-8717-685D27C6A4EE")!))
    func sendPromptAction_WhenWebViewIsAttached_UpdatesStateCorrectly() async {
        var stateChanges: [ComposerViewState] = []

        sut.$state
            .sink { state in stateChanges.append(state) }
            .store(in: &cancellables)

        webBridge.attach(to: webViewSpy)

        #expect(webBridge.webView === webViewSpy)

        _ = await sut.handle(action: .textChanged(to: "How to make proper neapolitan pizza?"))

        let effect = await sut.handle(action: .sendPromptTapped)

        let updatedState =
            initialState
            .copy(\.currentText, to: "")
            .copy(\.isProcessing, to: true)

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
                updatedState,
                initialState,
            ]
        )
        #expect(effect == .none)
    }

    @Test
    func sendPromptAction_WhenWebViewIsAttachedButJavaScriptEvaluationFails_ItReturnsError() async {
        var stateChanges: [ComposerViewState] = []

        sut.$state
            .sink { state in stateChanges.append(state) }
            .store(in: &cancellables)

        webBridge.attach(to: webViewSpy)

        #expect(webBridge.webView === webViewSpy)

        _ = await sut.handle(action: .textChanged(to: "Tell me a story"))

        webViewSpy.stubbedError = NSError(domain: "JS evaluation fails", code: -9006)

        let effect = await sut.handle(action: .sendPromptTapped)

        let updatedState =
            initialState
            .copy(\.currentText, to: "")
            .copy(\.isProcessing, to: true)

        #expect(
            stateChanges == [
                initialState,
                initialState.copy(\.currentText, to: "Tell me a story"),
                updatedState,
                initialState.copy(\.currentText, to: "Tell me a story"),
            ]
        )
        #expect(effect == .error(.evaluatingJSFailed(.sendPrompt("Tell me a story"))))
    }
}

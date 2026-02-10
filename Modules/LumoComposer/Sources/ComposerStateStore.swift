import Combine
import WebKit

@MainActor
final class ComposerStateStore: ObservableObject {
    enum Action {
        case textChanged(to: String)
        case sendPromptTapped
    }

    enum Effect: Equatable {
        case none
        case error(WebComposerBridgeError)
    }

    @Published var state: ComposerViewState

    private let webBridge: WebComposerBridging

    init(initialState: ComposerViewState, webBridge: WebComposerBridging) {
        self.state = initialState
        self.webBridge = webBridge
    }

    func handle(action: Action) async -> Effect {
        switch action {
        case .textChanged(let newText):
            state = state.copy(\.currentText, to: newText)
            return .none
        case .sendPromptTapped:
            let promptToSend: String = state.currentText

            state =
                state
                .copy(\.currentText, to: "")
                .copy(\.isProcessing, to: true)

            do {
                try await webBridge.sendPrompt(promptToSend)
                state = state.copy(\.isProcessing, to: false)
                return .none
            } catch {
                state =
                    state
                    .copy(\.currentText, to: promptToSend)
                    .copy(\.isProcessing, to: false)
                return .error(error)
            }
        }
    }
}

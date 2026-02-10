import Combine
import WebKit

@MainActor
final class ComposerStateStore: ObservableObject {
    enum Action {
        case taskStarted
        case onDisappear

        case textChanged(to: String)
        case sendPromptTapped
        case stopResponseTapped
        case openFilePickerTapped
        case toggleWebSearchTapped
        case startRecordingTapped
        case previewAttachmentTapped(id: String)
        case removeAttachmentTapped(id: String)
    }

    enum Effect: Equatable {
        case none
        case error(WebComposerBridgeError)
    }

    @Published var state: ComposerViewState

    private let webBridge: WebComposerBridging
    private var observationTask: Task<Void, Never>?

    init(initialState: ComposerViewState, webBridge: WebComposerBridging) {
        self.state = initialState
        self.webBridge = webBridge
    }

    func handle(action: Action) async -> Effect {
        switch action {
        case .taskStarted:
            observationTask?.cancel()
            observationTask = Task {
                for await webState in webBridge.stateUpdates {
                    guard !Task.isCancelled else { break }
                    state = state.copy(\.webState, to: webState)
                }
            }
            return .none

        case .onDisappear:
            observationTask?.cancel()
            observationTask = nil
            return .none

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

        case .stopResponseTapped:
            do {
                try await webBridge.stopResponse()
                return .none
            } catch {
                return .error(error)
            }

        case .openFilePickerTapped:
            do {
                try await webBridge.openFilePicker()
                return .none
            } catch {
                return .error(error)
            }

        case .toggleWebSearchTapped:
            do {
                try await webBridge.toggleWebSearch()
                return .none
            } catch {
                return .error(error)
            }

        case .startRecordingTapped:
            // FIXME: Implement when UI is migrated from main target
            return .none

        case .previewAttachmentTapped(let id):
            do {
                try await webBridge.previewAttachment(id: id)
                return .none
            } catch {
                return .error(error)
            }

        case .removeAttachmentTapped(let id):
            do {
                try await webBridge.removeAttachment(id: id)
                return .none
            } catch {
                return .error(error)
            }
        }
    }
}

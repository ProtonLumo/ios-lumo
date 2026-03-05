import Combine
import WebKit

final class ComposerStateStore: StateStore {
    enum Action {
        case webViewReadyChanged(Bool)
        case taskStarted
        case onDisappear

        case textChanged(String)
        case sendPromptTapped
        case stopResponseTapped
        case uploadFilesTapped([FileUploadData])
        case openProtonDriveTapped
        case openSketchTapped
        case toggleWebSearchTapped
        case toggleCreateImageTapped
        case changeModelTapped(WebComposerState.Model)
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

    func send(action: Action) async -> Effect {
        switch action {
        case .webViewReadyChanged(let newValue):
            state = state.copy(\.isWebViewReady, to: newValue)
            return .none
        case .taskStarted:
            observationTask?.cancel()
            observationTask = Task {
                for await webState in webBridge.stateUpdates {
                    guard !Task.isCancelled else { break }
                    state = state.copy(applyingWebState: webState)
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
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.stopResponse()
            }

        case .uploadFilesTapped(let files):
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.uploadFiles(files)
            }

        case .openProtonDriveTapped:
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.openProtonDrive()
            }

        case .openSketchTapped:
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.openSketch()
            }

        case .toggleWebSearchTapped:
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.toggleWebSearch()
            }

        case .toggleCreateImageTapped:
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.toggleCreateImage()
            }

        case .changeModelTapped(let modelType):
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.changeModel(modelType)
            }

        case .startRecordingTapped:
            // FIXME: Implement when UI is migrated from main target
            return .none

        case .previewAttachmentTapped(let id):
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.previewAttachment(id: id)
            }

        case .removeAttachmentTapped(let id):
            return await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.removeAttachment(id: id)
            }
        }
    }

    // MARK: - Private

    private func execute(_ command: () async throws(WebComposerBridgeError) -> Void) async -> Effect {
        do {
            try await command()
            return .none
        } catch {
            return .error(error)
        }
    }
}

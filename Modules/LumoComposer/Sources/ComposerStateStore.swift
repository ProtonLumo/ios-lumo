import Combine
import ProtonUIFoundations
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

        case showSheet(ActiveSheet)
        case dismissActiveSheet
        case toolsSheetAction(ToolsSheetView.Action)
        case modelSelectionSheetAction(ModelSelectionSheetView.Action)
    }

    @Published var state: ComposerViewState

    private let webBridge: WebComposerBridging
    private let toastStateStore: ToastStateStore
    private var observationTask: Task<Void, Never>?

    init(initialState: ComposerViewState, webBridge: WebComposerBridging, toastStateStore: ToastStateStore) {
        self.state = initialState
        self.webBridge = webBridge
        self.toastStateStore = toastStateStore
    }

    func send(action: Action) async {
        switch action {
        case .webViewReadyChanged(let newValue):
            state = state.copy(\.isWebViewReady, to: newValue)

        case .taskStarted:
            observationTask?.cancel()
            observationTask = Task {
                for await webState in webBridge.stateUpdates {
                    guard !Task.isCancelled else { break }
                    state = state.copy(applyingWebState: webState)
                }
            }

        case .onDisappear:
            observationTask?.cancel()
            observationTask = nil

        case .textChanged(let newText):
            state = state.copy(\.currentText, to: newText)

        case .sendPromptTapped:
            let promptToSend: String = state.currentText

            state =
                state
                .copy(\.currentText, to: "")
                .copy(\.isProcessing, to: true)

            do {
                try await webBridge.sendPrompt(promptToSend)
                state = state.copy(\.isProcessing, to: false)
            } catch {
                state =
                    state
                    .copy(\.currentText, to: promptToSend)
                    .copy(\.isProcessing, to: false)
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }

        case .stopResponseTapped:
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.stopResponse()
            }

        case .uploadFilesTapped(let files):
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.uploadFiles(files)
            }

        case .openProtonDriveTapped:
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.openProtonDrive()
            }

        case .openSketchTapped:
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.openSketch()
            }

        case .toggleWebSearchTapped:
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.toggleWebSearch()
            }

        case .toggleCreateImageTapped:
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.toggleCreateImage()
            }

        case .changeModelTapped(let modelType):
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.changeModel(modelType)
            }

        case .startRecordingTapped:
            // FIXME: Implement when UI is migrated from main target
            break

        case .previewAttachmentTapped(let id):
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.previewAttachment(id: id)
            }

        case .removeAttachmentTapped(let id):
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.removeAttachment(id: id)
            }

        case .showSheet(let sheet):
            state = state.copy(\.activeSheet, to: sheet)

        case .dismissActiveSheet:
            state = state.copy(\.activeSheet, to: nil)

        case .toolsSheetAction(let action):
            switch action {
            case .createImageTapped:
                state = state.copy(\.activeSheet, to: nil)
                await execute { () async throws(WebComposerBridgeError) in
                    try await webBridge.toggleCreateImage()
                }
            case .webSearchToggled:
                await execute { () async throws(WebComposerBridgeError) in
                    try await webBridge.toggleWebSearch()
                }
            case .closeTapped:
                state = state.copy(\.activeSheet, to: nil)
            }

        case .modelSelectionSheetAction(let action):
            switch action {
            case .modelSelected(let model):
                // FIXME: Show upsell for free users when model == .thinking
                state = state.copy(\.activeSheet, to: nil)
                await execute { () async throws(WebComposerBridgeError) in
                    try await webBridge.changeModel(model)
                }
            case .closeTapped:
                state = state.copy(\.activeSheet, to: nil)
            }
        }
    }

    // MARK: - Private

    private func execute(_ command: () async throws(WebComposerBridgeError) -> Void) async {
        do {
            try await command()
        } catch {
            toastStateStore.present(toast: .error(message: error.localizedDescription))
        }
    }
}

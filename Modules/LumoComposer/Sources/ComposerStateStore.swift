import Combine
import PhotosUI
import ProtonUIFoundations
import UIKit
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

        case showPicker(ActiveSystemPicker)
        case dismissActivePicker
        case filesPicked(Result<URL, any Error>)
        case photoPicked(any PhotosItemLoading)
        case imageCaptured(UIImage)
    }

    typealias FileLoader = @Sendable (URL) throws -> Data

    @Published var state: ComposerViewState

    private let webBridge: WebComposerBridging
    private let toastStateStore: ToastStateStore
    private let fileLoader: FileLoader
    private var observationTask: Task<Void, Never>?

    init(
        initialState: ComposerViewState,
        webBridge: WebComposerBridging,
        toastStateStore: ToastStateStore,
        fileLoader: @escaping FileLoader = { url in try securityScopedFileLoader(url: url) }
    ) {
        self.state = initialState
        self.webBridge = webBridge
        self.toastStateStore = toastStateStore
        self.fileLoader = fileLoader
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

        case .showPicker(let picker):
            state = state.copy(\.activeSystemPicker, to: picker)

        case .dismissActivePicker:
            state = state.copy(\.activeSystemPicker, to: nil)

        case .filesPicked(let result):
            guard case .success(let url) = result else { return }
            do {
                let data = try fileLoader(url)
                await sendUploadFile(data: data, name: url.lastPathComponent)
            } catch {}

        case .photoPicked(let item):
            do {
                guard let data = try await item.loadTransferableData() else { return }
                let name = PhotoFileNameExtractor.fileName(from: item)
                await sendUploadFile(data: data, name: name)
            } catch {}

        case .imageCaptured(let image):
            guard let data = image.jpegData(compressionQuality: 1) else { return }
            let name = "\(UUIDEnvironment.uuid().uuidString).jpg"
            await sendUploadFile(data: data, name: name)
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

    private func sendUploadFile(data: Data, name: String) async {
        let base64 = data.base64EncodedString()
        let file = FileUploadData(base64: base64, name: name)

        await send(action: .uploadFilesTapped([file]))
    }
}

import Combine
import LumoCore
import PhotosUI
import ProtonUIFoundations
import UIKit

final class ComposerStateStore: StateStore {
    private let freeUserThinkingTappedSubject = PassthroughSubject<Void, Never>()

    var freeUserThinkingTappedPublisher: AnyPublisher<Void, Never> {
        freeUserThinkingTappedSubject.eraseToAnyPublisher()
    }

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
        case toggleCreateImageTapped
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

        case recorder(RecorderAction)
    }

    enum RecorderAction {
        case submit
        case cancel
        case dismissPermissionAlert
        case openSettings
    }

    typealias FileLoader = @Sendable (URL) throws -> Data

    @Published var state: ComposerViewState

    private let webBridge: WebComposerBridging
    private let toastStateStore: ToastStateStore
    private let fileLoader: FileLoader
    private let speechService: SpeechRecordingServiceProtocol
    private let urlOpener: URLOpenerProtocol
    private var stateObservationTask: Task<Void, Never>?
    private var errorObservationTask: Task<Void, Never>?
    private var speechStore: SpeechStateStore?
    private var speechStateCancellable: Set<AnyCancellable> = []

    init(
        initialState: ComposerViewState,
        webBridge: WebComposerBridging,
        toastStateStore: ToastStateStore,
        speechService: SpeechRecordingServiceProtocol,
        urlOpener: URLOpenerProtocol,
        fileLoader: @escaping FileLoader = { url in try securityScopedFileLoader(url: url) }
    ) {
        self.state = initialState
        self.webBridge = webBridge
        self.toastStateStore = toastStateStore
        self.speechService = speechService
        self.urlOpener = urlOpener
        self.fileLoader = fileLoader
    }

    func send(action: Action) async {
        switch action {
        case .webViewReadyChanged(let newValue):
            state = state.copy(\.isWebViewReady, to: newValue)

        case .taskStarted:
            stateObservationTask?.cancel()
            stateObservationTask = Task {
                for await webState in webBridge.stateUpdates {
                    guard !Task.isCancelled else { break }
                    state = state.copy(applyingWebState: webState)
                }
            }
            errorObservationTask?.cancel()
            errorObservationTask = Task {
                for await error in webBridge.errorUpdates {
                    guard !Task.isCancelled else { break }
                    toastStateStore.present(toast: .error(message: error.localizedDescription))
                }
            }

        case .onDisappear:
            stateObservationTask?.cancel()
            stateObservationTask = nil
            errorObservationTask?.cancel()
            errorObservationTask = nil
            detachSpeechStore()
            state.speechState = .idle

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

        case .toggleCreateImageTapped:
            await execute { () async throws(WebComposerBridgeError) in
                try await webBridge.toggleCreateImage()
            }

        case .startRecordingTapped:
            let store = SpeechStateStore(service: speechService, urlOpener: urlOpener)
            store
                .$state
                .sink { [weak self] speechState in self?.state.speechState = speechState }
                .store(in: &speechStateCancellable)
            store.onTranscriptionComplete = { [weak self] text in
                self?.state.currentText = text
            }
            speechStore = store
            await store.send(action: .startRecording)

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
            state = state.copy(\.activeSheet, to: nil)

            switch action {
            case .modelSelected(let model):
                switch model {
                case .thinking where state.webState.userFlags.isGuestUser:
                    await execute { () async throws(WebComposerBridgeError) in
                        try await webBridge.openAccount()
                    }
                case .thinking where state.webState.userFlags.isFreeUser:
                    freeUserThinkingTappedSubject.send()
                case .auto, .fast, .thinking:
                    await execute { () async throws(WebComposerBridgeError) in
                        try await webBridge.changeModelTier(model)
                    }
                }
            case .closeTapped:
                break
            }

        case .showPicker(let picker):
            state = state.copy(\.activeSystemPicker, to: picker)

        case .dismissActivePicker:
            state = state.copy(\.activeSystemPicker, to: nil)

        case .filesPicked(let result):
            switch result {
            case .success(let url):
                do {
                    let data = try fileLoader(url)
                    await sendUploadFile(data: data, name: url.lastPathComponent)
                } catch {
                    toastStateStore.present(toast: .error(message: L10n.Error.generic.string))
                }
            case .failure:
                toastStateStore.present(toast: .error(message: L10n.Error.generic.string))
            }

        case .photoPicked(let item):
            do {
                guard let data = try await item.loadTransferableData() else { return }
                let name = PhotoFileNameExtractor.fileName(from: item)
                await sendUploadFile(data: data, name: name)
            } catch {
                toastStateStore.present(toast: .error(message: L10n.Error.generic.string))
            }

        case .imageCaptured(let image):
            guard let data = image.jpegData(compressionQuality: 0.7) else { return }
            let name = "\(UUIDEnvironment.uuid().uuidString).jpg"
            await sendUploadFile(data: data, name: name)

        case .recorder(let recorderAction):
            switch recorderAction {
            case .submit:
                await speechStore?.send(action: .submitRecording)
                detachSpeechStore()
            case .cancel:
                await speechStore?.send(action: .cancelRecording)
                detachSpeechStore()
            case .dismissPermissionAlert:
                await speechStore?.send(action: .dismissPermissionAlert)
                detachSpeechStore()
            case .openSettings:
                await speechStore?.send(action: .openSettings)
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

    private func sendUploadFile(data: Data, name: String) async {
        let base64 = data.base64EncodedString()
        let file = FileUploadData(base64: base64, name: name)

        await send(action: .uploadFilesTapped([file]))
    }

    private func detachSpeechStore() {
        speechStore = nil
        speechStateCancellable = []
    }
}

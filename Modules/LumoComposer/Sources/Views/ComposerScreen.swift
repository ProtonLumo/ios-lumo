import Lottie
import LumoDesignSystem
import PhotosUI
import ProtonUIFoundations
import SwiftUI
import UIKit

public struct ComposerScreen<WebContent: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var store: ComposerStateStore
    private let isWebViewReady: Bool
    private let toastStateStore: ToastStateStore
    @ViewBuilder private let webContent: () -> WebContent

    @State private var sheetHeight: CGFloat = 250
    @State private var isPhotoPickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isFileImporterPresented = false
    @State private var isCameraPickerPresented = false

    public init(
        webBridge: WebComposerBridging,
        isWebViewReady: Bool,
        toastStateStore: ToastStateStore,
        webContent: @escaping () -> WebContent
    ) {
        self.init(
            initialState: .initial,
            webBridge: webBridge,
            isWebViewReady: isWebViewReady,
            toastStateStore: toastStateStore,
            webContent: webContent
        )
    }

    /// - Parameter initialState: Exposed for snapshot testing with different states
    init(
        initialState: ComposerViewState,
        webBridge: WebComposerBridging,
        isWebViewReady: Bool,
        toastStateStore: ToastStateStore,
        webContent: @escaping () -> WebContent
    ) {
        _store = .init(
            wrappedValue: .init(
                initialState: initialState,
                webBridge: webBridge,
                toastStateStore: toastStateStore
            )
        )
        self.isWebViewReady = isWebViewReady
        self.toastStateStore = toastStateStore
        self.webContent = webContent
    }

    // MARK: - View

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .center) {
                webContent()

                if !store.state.isWebViewReady && store.state.webState.isVisible {
                    placeholders(screenSize: proxy.size)
                }

                VStack(spacing: DS.Spacing.medium) {
                    Spacer()
                    if store.state.webState.isVisible && store.state.webState.showTermsAndPrivacy {
                        TermsAndPrivacyText()
                    }

                    if store.state.webState.isVisible {
                        ComposerView(
                            text: .init(
                                get: { store.state.currentText },
                                set: { newValue in store.send(action: .textChanged(newValue)) }
                            ),
                            files: store.state.webState.attachedFiles,
                            model: store.state.webState.model,
                            isCreateImageEnabled: store.state.webState.isCreateImageEnabled,
                            isGhostModeEnabled: store.state.webState.isGhostModeEnabled,
                            isWebSearchEnabled: store.state.webState.isWebSearchEnabled,
                            areButtonsDisabled: !store.state.isWebViewReady,
                            actionButton: store.state.actionButton,
                            action: handle(action:)
                        )
                        .padding(.horizontal, DS.Spacing.large)
                        .padding(.bottom, DS.Spacing.standard)
                    }
                }
            }
        }
        .onChange(of: isWebViewReady, initial: true) { _, newValue in
            store.send(action: .webViewReadyChanged(newValue))
        }
        .task { store.send(action: .taskStarted) }
        .onDisappear { store.send(action: .onDisappear) }
        .sheet(item: activeSheetBinding) { sheet in
            sheetContent(for: sheet)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: SheetHeightKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(SheetHeightKey.self) { sheetHeight = $0 }
                .presentationDetents([.height(sheetHeight)])
                .presentationDragIndicator(.visible)
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, photosItem in
            if let photosItem {
                Task {
                    await upload(photosItem: photosItem)
                    selectedPhotoItem = nil
                }
            }
        }
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.data]) { result in
            Task {
                await upload(fileResult: result)
            }
        }
        .sheet(isPresented: $isCameraPickerPresented) {
            CameraPickerView(
                onImageCaptured: { image in
                    Task { await upload(capturedImage: image) }
                },
                onDismiss: { isCameraPickerPresented = false }
            )
            .ignoresSafeArea()
        }
        .environment(\.featureFlags, store.state.webState.featureFlags)
    }

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .tools:
            ToolsSheetView(
                isWebSearchEnabled: store.state.webState.isWebSearchEnabled,
                action: { action in store.send(action: .toolsSheetAction(action)) }
            )
        case .modelSelection:
            ModelSelectionSheetView(
                selectedModel: store.state.webState.model,
                action: { action in store.send(action: .modelSelectionSheetAction(action)) }
            )
        }
    }

    private var activeSheetBinding: Binding<ActiveSheet?> {
        Binding(
            get: { store.state.activeSheet },
            set: { if $0 == nil { store.send(action: .dismissActiveSheet) } }
        )
    }

    // MARK: - Private

    private func handle(action: ComposerView.Action) {
        switch action {
        case .sendTapped:
            store.send(action: .sendPromptTapped)
        case .stopTapped:
            store.send(action: .stopResponseTapped)
        case .attachmentOptionChosen(let option):
            switch option {
            case .protonDrive:
                store.send(action: .openProtonDriveTapped)
            case .files:
                isFileImporterPresented = true
            case .camera:
                isCameraPickerPresented = true
            case .photos:
                isPhotoPickerPresented = true
            case .sketch:
                store.send(action: .openSketchTapped)
            }
        case .exitImageModeTapped:
            store.send(action: .toggleCreateImageTapped)
        case .toolsTapped:
            store.send(action: .showSheet(.tools))
        case .modelSelectionTapped:
            store.send(action: .showSheet(.modelSelection))
        case .microphoneTapped:
            store.send(action: .startRecordingTapped)
        case .attachmentTapped(let id):
            store.send(action: .previewAttachmentTapped(id: id))
        case .removeAttachmentTapped(let id):
            store.send(action: .removeAttachmentTapped(id: id))
        }
    }

    private func placeholders(screenSize: CGSize) -> some View {
        VStack(spacing: DS.Spacing.medium) {
            logoPlaceholder()
            Spacer()
            catPlaceholder(offsetY: -screenSize.height * 0.07)
            Spacer()
        }
        .ignoresSafeArea(.keyboard)
    }

    private func logoPlaceholder() -> some View {
        HStack(spacing: .zero) {
            DS.Icon.lumoLogo.swiftUIImage
                .foregroundStyle(DS.Color.Text.norm)
                .padding(.top, DS.Spacing.large)
                .padding(.leading, 58)
            Spacer()
        }
    }

    private func catPlaceholder(offsetY: CGFloat) -> some View {
        VStack(spacing: -DS.Spacing.standard) {
            lottieView()
            ComposerWelcomeText()
        }
        .offset(y: offsetY)
    }

    private func lottieView() -> some View {
        Group {
            if let progress = LottieEnvironment.pausedAt {
                LottieView(animation: animation)
                    .snapshotMode(at: progress)
            } else {
                LottieView(animation: animation)
                    .playbackInLoopMode()
            }
        }
        .frame(width: 220, height: 201)
    }

    private var animation: LottieAnimation {
        let darkItem = LottieAnimations.LumoCat.dark
        let lightItem = LottieAnimations.LumoCat.light

        return colorScheme == .dark ? darkItem : lightItem
    }

    private func upload(fileResult: Result<URL, Error>) async {
        guard case .success(let url) = fileResult else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else { return }

        await upload(data: data, name: url.lastPathComponent)
    }

    private func upload(capturedImage: UIImage) async {
        guard let data = capturedImage.jpegData(compressionQuality: 1) else { return }

        let name = "\(UUIDEnvironment.uuid().uuidString).jpg"

        await upload(data: data, name: name)
    }

    private func upload(photosItem: PhotosPickerItem) async {
        guard let data = try? await photosItem.loadTransferable(type: Data.self) else { return }

        let name = PhotoFileNameExtractor.fileName(from: photosItem)

        await upload(data: data, name: name)
    }

    private func upload(data: Data, name: String) async {
        let base64 = data.base64EncodedString()
        let file = FileUploadData(base64: base64, name: name)

        await store.send(action: .uploadFilesTapped([file]))
    }
}

private struct SheetHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#if DEBUG
    #Preview {
        ComposerScreen(
            initialState: .initial,
            webBridge: WebComposerBridge(),
            isWebViewReady: true,
            toastStateStore: ToastStateStore(initialState: .initial),
            webContent: { EmptyView() }
        )
    }
#endif

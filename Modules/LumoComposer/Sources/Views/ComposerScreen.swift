import Lottie
import LumoDesignSystem
import SwiftUI

public struct ComposerScreen<WebContent: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var store: ComposerStateStore
    @State private var activeSheet: ActiveSheet?
    @State private var sheetHeight: CGFloat = 250
    private let isWebViewReady: Bool
    @ViewBuilder private let webContent: () -> WebContent

    public init(
        webBridge: WebComposerBridging,
        isWebViewReady: Bool,
        webContent: @escaping () -> WebContent
    ) {
        self.init(
            initialState: .initial,
            webBridge: webBridge,
            isWebViewReady: isWebViewReady,
            webContent: webContent
        )
    }

    /// - Parameter initialState: Exposed for snapshot testing with different states
    init(
        initialState: ComposerViewState,
        webBridge: WebComposerBridging,
        isWebViewReady: Bool,
        webContent: @escaping () -> WebContent
    ) {
        _store = .init(
            wrappedValue: .init(
                initialState: initialState,
                webBridge: webBridge
            )
        )
        self.isWebViewReady = isWebViewReady
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
        .sheet(item: $activeSheet) { sheet in
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
    }

    @ViewBuilder
    private func sheetContent(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .tools:
            ToolsSheetView(
                isWebSearchEnabled: store.state.webState.isWebSearchEnabled,
                action: handle(toolsSheetAction:)
            )
        case .modelSelection:
            ModelSelectionSheetView(
                selectedModel: store.state.webState.model,
                action: handle(modelSelectionSheetAction:)
            )
        }
    }

    private func handle(toolsSheetAction action: ToolsSheetView.Action) {
        switch action {
        case .createImageTapped:
            store.send(action: .toggleCreateImageTapped)
            activeSheet = nil
        case .webSearchToggled:
            store.send(action: .toggleWebSearchTapped)
        case .closeTapped:
            activeSheet = nil
        }
    }

    private func handle(modelSelectionSheetAction action: ModelSelectionSheetView.Action) {
        switch action {
        case .modelSelected(let model):
            // FIXME: Show upsell for free users when model == .thinking
            store.send(action: .changeModelTapped(model))
            activeSheet = nil
        case .closeTapped:
            activeSheet = nil
        }
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
                // FIXME: Open native files picker and transform selected file to base64 and use
                // store.send(action: .uploadFilesTapped([.init(base64: {{base64}}, name: {{fileName}})]))
                break
            case .camera:
                // FIXME: Open native camera picker and transform captured photo to base64 and use
                // store.send(action: .uploadFilesTapped([.init(base64: {{base64}}, name: {{fileName}})]))
                break
            case .photos:
                // FIXME: Open photos picker and transform selected photo to base64 and use
                // store.send(action: .uploadFilesTapped([.init(base64: {{base64}}, name: {{fileName}})]))
                break
            case .sketch:
                store.send(action: .openSketchTapped)
            }
        case .exitImageModeTapped:
            store.send(action: .toggleCreateImageTapped)
        case .toolsTapped:
            activeSheet = .tools
        case .modelSelectionTapped:
            activeSheet = .modelSelection
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
}

private enum ActiveSheet: String, Identifiable {
    case tools
    case modelSelection

    var id: String {
        rawValue
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
            webContent: { EmptyView() }
        )
    }
#endif

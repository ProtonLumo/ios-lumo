import Lottie
import LumoDesignSystem
import SwiftUI

public struct ComposerScreen<WebContent: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var store: ComposerStateStore
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
            // FIXME: Show native sheet that has two options:
            // - "Create image" which triggerss `store.send(action: .toggleCreateImageTapped)`
            // - "Web search" toggle which triggerss `store.send(action: .toggleWebSearchTapped)`
            break
        case .modelSelectionTapped:
            // FIXME: Show native sheet that has three options:
            // - "Auto" which triggerss `store.send(action: .changeModelTapped(.auto))`
            // - "Fast" which triggerss `store.send(action: .changeModelTapped(.fast))`
            // - "Thinking" which triggerss `store.send(action: .changeModelTapped(.thinking))` if it's paid if it's free user shows an upsel
            break
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

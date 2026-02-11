import Lottie
import LumoDesignSystem
import SwiftUI

public struct ComposerScreen: View {
    @StateObject var store: ComposerStateStore
    @Environment(\.colorScheme) var colorScheme
    private let isWebViewReady: Bool

    public init(webBridge: WebComposerBridging, isWebViewReady: Bool) {
        self.init(initialState: .initial, webBridge: webBridge, isWebViewReady: isWebViewReady)
    }

    /// - Parameter initialState: Exposed for snapshot testing with different states
    init(
        initialState: ComposerViewState,
        webBridge: WebComposerBridging,
        isWebViewReady: Bool
    ) {
        _store = .init(
            wrappedValue: .init(
                initialState: initialState,
                webBridge: webBridge
            )
        )
        self.isWebViewReady = isWebViewReady
    }

    // MARK: - View

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .center) {
                placeholders(screenSize: proxy.size)

                VStack(spacing: DS.Spacing.medium) {
                    Spacer()
                    TermsAndPrivacyText()
                    ComposerView(
                        text: .init(
                            get: { store.state.currentText },
                            set: { newValue in store.send(action: .textChanged(newValue)) }
                        ),
                        files: store.state.webState.attachedFiles,
                        isGhostModeEnabled: store.state.webState.isGhostModeEnabled,
                        isWebSearchEnabled: store.state.webState.isWebSearchEnabled,
                        areButtonsDisabled: !store.state.isWebViewReady,
                        actionButton: store.state.actionButton,
                        action: handle(action:)
                    )
                    .padding(.horizontal, DS.Spacing.tiny)
                    .padding(.bottom, DS.Spacing.standard)
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
        case .filePickerTapped:
            store.send(action: .openFilePickerTapped)
        case .webSearchTapped:
            store.send(action: .toggleWebSearchTapped)
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
            isWebViewReady: true
        )
    }
#endif

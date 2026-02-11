import Lottie
import LumoDesignSystem
import SwiftUI

public struct ComposerScreen: View {
    @StateObject var store: ComposerStateStore
    @Environment(\.colorScheme) var colorScheme

    init(initialState: ComposerViewState?, webBridge: WebComposerBridging) {
        _store = .init(
            wrappedValue: .init(
                initialState: initialState ?? .initial,
                webBridge: webBridge
            )
        )
    }

    // MARK: - View

    public var body: some View {
        ZStack {
            catPlaceholder()

            VStack(spacing: DS.Spacing.medium) {
                logoPlaceholder()
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
                    actionButton: store.state.actionButton,
                    action: { action in didReceive(action: action) }
                )
                .padding(.horizontal, DS.Spacing.tiny)
                .padding(.bottom, DS.Spacing.standard)
            }
        }
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

    private func catPlaceholder() -> some View {
        VStack(spacing: -DS.Spacing.standard) {
            lottieView()
            ComposerWelcomeText()
        }
        .offset(y: -DS.Spacing.extraLarge)
    }

    // MARK: - Private

    private func didReceive(action: ComposerView.Action) {
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
        ComposerScreen(initialState: .initial, webBridge: WebComposerBridge())
    }
#endif

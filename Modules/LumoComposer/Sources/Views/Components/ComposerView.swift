import LumoDesignSystem
import SwiftUI

struct ComposerView: View {
    enum Action {
        case sendTapped
        case stopTapped
        case filePickerTapped
        case webSearchTapped
        case microphoneTapped
    }

    enum ActionButtonState {
        case none
        case send
        case stop
    }

    @Binding var text: String
    let isGhostModeEnabled: Bool
    let isWebSearchEnabled: Bool
    let actionButton: ActionButtonState
    let action: (Action) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            HStack(alignment: .center, spacing: DS.Spacing.small) {
                ComposerInput(text: $text, isGhostModeEnabled: isGhostModeEnabled)
                    .background(isGhostModeEnabled ? DS.Color.Background.weakDarkOnly : DS.Color.Background.weak)
                    .padding(.vertical, DS.Spacing.large)

                switch actionButton {
                case .none:
                    EmptyView()
                case .send:
                    sendButton
                case .stop:
                    stopButton
                }
            }
            .frame(minHeight: 52)
            .padding(.horizontal, DS.Spacing.mediumLight)
            .background {
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .fill(isGhostModeEnabled ? DS.Color.Background.weakDarkOnly : DS.Color.Background.weak)
            }

            ComposerToolbar(
                isGhostModeEnabled: isGhostModeEnabled,
                isWebSearchEnabled: isWebSearchEnabled,
                onPaperclipTap: { action(.filePickerTapped) },
                onGlobeTap: { action(.webSearchTapped) },
                onMicrophoneTap: { action(.microphoneTapped) }
            )
        }
        .padding(.all, DS.Spacing.compact)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.massive)
                .fill(isGhostModeEnabled ? DS.Color.Background.normDarkOnly : DS.Color.Background.weak)
        }
    }

    private var sendButton: some View {
        ComposerActionButton(
            action: { action(.sendTapped) },
            icon: DS.Icon.arrowRight,
            isGhostModeEnabled: isGhostModeEnabled
        )
    }

    private var stopButton: some View {
        ComposerActionButton(
            action: { action(.stopTapped) },
            icon: DS.Icon.stop,
            isGhostModeEnabled: isGhostModeEnabled
        )
    }
}

#if DEBUG
    #Preview {
        VStack {
            Spacer()
            ComposerView(
                text: .constant(""),
                isGhostModeEnabled: false,
                isWebSearchEnabled: true,
                actionButton: .none,
                action: { _ in }
            )
            ComposerView(
                text: .constant("Tell me a long story"),
                isGhostModeEnabled: false,
                isWebSearchEnabled: false,
                actionButton: .send,
                action: { _ in }
            )
            ComposerView(
                text: .constant(""),
                isGhostModeEnabled: true,
                isWebSearchEnabled: false,
                actionButton: .stop,
                action: { _ in }
            )
            ComposerView(
                text: .constant("Tell me a long story"),
                isGhostModeEnabled: true,
                isWebSearchEnabled: true,
                actionButton: .send,
                action: { _ in }
            )
        }
        .background(Color.gray)
    }
#endif

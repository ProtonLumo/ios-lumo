import LumoDesignSystem
import SwiftUI

struct ComposerView: View {
    enum Action {
        case sendTapped
        case stopTapped
        case filePickerTapped
        case webSearchTapped
        case microphoneTapped
        case attachmentTapped(id: String)
        case removeAttachmentTapped(id: String)
    }

    enum ActionButtonState {
        case none
        case send
        case stop
    }

    @Binding var text: String
    let files: [File]
    let isGhostModeEnabled: Bool
    let isWebSearchEnabled: Bool
    let areButtonsDisabled: Bool
    let actionButton: ActionButtonState
    let action: (Action) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            if !files.isEmpty {
                ComposerAttachmentsView(
                    files: files,
                    accentColor: accentColor,
                    backgroundColor: backgroundColor,
                    borderColor: isGhostModeEnabled ? DS.Color.Border.weakDark : DS.Color.Border.weak,
                    onAttachmentTapped: { id in action(.attachmentTapped(id: id)) },
                    onTrashTapped: { id in action(.removeAttachmentTapped(id: id)) }
                )
            }

            HStack(alignment: .center, spacing: DS.Spacing.small) {
                ComposerInput(
                    text: $text,
                    placeholderColor: isGhostModeEnabled ? DS.Color.Text.hintDark : DS.Color.Text.hint,
                    textColor: isGhostModeEnabled ? DS.Color.Text.normDarkOnly : DS.Color.Text.norm,
                    backgroundColor: backgroundColor
                )

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
                    .fill(backgroundColor)
            }

            ComposerToolbar(
                iconColor: accentColor,
                isWebSearchEnabled: isWebSearchEnabled,
                onPaperclipTap: { action(.filePickerTapped) },
                onGlobeTap: { action(.webSearchTapped) },
                onMicrophoneTap: { action(.microphoneTapped) }
            )
            .disabled(areButtonsDisabled)
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
            icon: DS.Icon.icArrowRight.swiftUIImage,
            iconColor: actionButtonIconColor
        )
    }

    private var stopButton: some View {
        ComposerActionButton(
            action: { action(.stopTapped) },
            icon: DS.Icon.icStop.swiftUIImage,
            iconColor: actionButtonIconColor
        )
    }

    private var accentColor: Color {
        isGhostModeEnabled ? DS.Color.Text.weakDark : DS.Color.Text.weak
    }

    private var actionButtonIconColor: Color {
        isGhostModeEnabled ? DS.Color.Background.normDarkOnly : DS.Color.Background.norm
    }

    private var backgroundColor: Color {
        isGhostModeEnabled ? DS.Color.Background.weakDarkOnly : DS.Color.Background.weak
    }
}

#if DEBUG
    #Preview {
        VStack {
            Spacer()
            ComposerView(
                text: .constant(""),
                files: [
                    .init(id: "1", name: "Report.pdf", type: .pdf, preview: .none),
                    .init(id: "2", name: "Data.xls", type: .xls, preview: .none),
                    .init(id: "3", name: "Slides.ppt", type: .ppt, preview: .none),
                    .init(id: "4", name: "Image.jpg", type: .image, preview: .none),
                    .init(id: "5", name: "Video.mp4", type: .video, preview: .none),
                ],
                isGhostModeEnabled: false,
                isWebSearchEnabled: true,
                areButtonsDisabled: false,
                actionButton: .none,
                action: { _ in }
            )
            ComposerView(
                text: .constant("Tell me a long story"),
                files: [],
                isGhostModeEnabled: false,
                isWebSearchEnabled: false,
                areButtonsDisabled: true,
                actionButton: .send,
                action: { _ in }
            )
            ComposerView(
                text: .constant(""),
                files: [],
                isGhostModeEnabled: true,
                isWebSearchEnabled: false,
                areButtonsDisabled: false,
                actionButton: .stop,
                action: { _ in }
            )
            ComposerView(
                text: .constant("Tell me a long story"),
                files: [
                    .init(id: "1", name: "Report.pdf", type: .pdf, preview: .none),
                    .init(id: "2", name: "Data.xls", type: .xls, preview: .none),
                    .init(id: "3", name: "Slides.ppt", type: .ppt, preview: .none),
                    .init(id: "4", name: "Image.jpg", type: .image, preview: .none),
                    .init(id: "5", name: "Video.mp4", type: .video, preview: .none),
                ],
                isGhostModeEnabled: true,
                isWebSearchEnabled: true,
                areButtonsDisabled: false,
                actionButton: .send,
                action: { _ in }
            )
        }
        .background(Color.gray)
    }
#endif

import LumoDesignSystem
import SwiftUI

struct ComposerView: View {
    @Environment(\.featureFlags) var featureFlags: WebComposerState.FeatureFlags

    enum Action {
        case sendTapped
        case stopTapped
        case attachmentOptionChosen(AddAttachmentOption)
        case exitImageModeTapped
        case toolsTapped
        case modelSelectionTapped
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
    let model: WebComposerState.Model
    let isCreateImageEnabled: Bool
    let isGhostModeEnabled: Bool
    let isWebSearchEnabled: Bool
    let areButtonsDisabled: Bool
    let actionButton: ActionButtonState
    let action: (Action) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.large) {
            if !files.isEmpty {
                ComposerAttachmentsView(
                    files: files,
                    accentColor: accentColor,
                    backgroundColor: isGhostModeEnabled ? DS.Color.Background.weakDarkOnly : DS.Color.Background.weak,
                    borderColor: isGhostModeEnabled ? DS.Color.Border.weakDark : DS.Color.Border.weak,
                    onAttachmentTapped: { id in action(.attachmentTapped(id: id)) },
                    onRemoveTapped: { id in action(.removeAttachmentTapped(id: id)) }
                )
            }

            HStack(alignment: .center, spacing: DS.Spacing.small) {
                ComposerInput(
                    text: $text,
                    placeholderText: featureFlags.isImageGenEnabled && isCreateImageEnabled ? L10n.Composer.placeholderImage : L10n.Composer.placeholder,
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
                model: model,
                iconColor: accentColor,
                isCreateImageEnabled: isCreateImageEnabled,
                isWebSearchEnabled: isWebSearchEnabled,
                areButtonsDisabled: areButtonsDisabled,
                action: { chosenAction in
                    switch chosenAction {
                    case .attachmentOptionChosen(let option):
                        action(.attachmentOptionChosen(option))
                    case .exitImageModeTapped:
                        action(.exitImageModeTapped)
                    case .toolsTapped:
                        action(.toolsTapped)
                    case .modelSelectionTapped:
                        action(.modelSelectionTapped)
                    case .microphoneTapped:
                        action(.microphoneTapped)
                    }
                }
            )
            .padding(.horizontal, DS.Spacing.mediumLight)
            .disabled(areButtonsDisabled)
        }
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.compact)
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.massive)
                .fill(isGhostModeEnabled ? DS.Color.Background.normDarkOnly : DS.Color.Text.invert)
                .strokeBorder(isGhostModeEnabled ? Color.clear : DS.Color.Border.norm, lineWidth: 1)
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
        isGhostModeEnabled ? DS.Color.Text.normDarkOnly : DS.Color.Text.norm
    }

    private var actionButtonIconColor: Color {
        isGhostModeEnabled ? DS.Color.Background.normDarkOnly : DS.Color.Background.norm
    }

    private var backgroundColor: Color {
        isGhostModeEnabled ? DS.Color.Background.weakDarkOnly : DS.Color.Text.invert
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
                model: .auto,
                isCreateImageEnabled: false,
                isGhostModeEnabled: false,
                isWebSearchEnabled: true,
                areButtonsDisabled: false,
                actionButton: .none,
                action: { _ in }
            )
            ComposerView(
                text: .constant("Tell me a long story"),
                files: [],
                model: .fast,
                isCreateImageEnabled: true,
                isGhostModeEnabled: false,
                isWebSearchEnabled: false,
                areButtonsDisabled: true,
                actionButton: .send,
                action: { _ in }
            )
            ComposerView(
                text: .constant(""),
                files: [],
                model: .thinking,
                isCreateImageEnabled: true,
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
                model: .thinking,
                isCreateImageEnabled: true,
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

import LumoDesignSystem
import SwiftUI

struct ComposerToolbar: View {
    enum Action {
        case attachmentOptionChosen(AddAttachmentOption)
        case exitImageModeTapped
        case toolsTapped
        case modelSelectionTapped
        case microphoneTapped
    }

    let model: WebComposerState.Model
    let iconColor: Color
    let isCreateImageEnabled: Bool
    let isWebSearchEnabled: Bool
    let areButtonsDisabled: Bool
    let action: (Action) -> Void

    var body: some View {
        HStack(spacing: .zero) {
            HStack(spacing: DS.Spacing.large) {
                Menu(
                    content: {
                        Section {
                            AddAttachmentButton(title: L10n.Attachment.protonDrive, icon: DS.Icon.icBrandProtonDrive.swiftUIImage) {
                                action(.attachmentOptionChosen(.protonDrive))
                            }
                            AddAttachmentButton(title: L10n.Attachment.files, icon: DS.Icon.icPaperClip.swiftUIImage) {
                                action(.attachmentOptionChosen(.files))
                            }
                            AddAttachmentButton(title: L10n.Attachment.camera, icon: DS.Icon.icCamera.swiftUIImage) {
                                action(.attachmentOptionChosen(.camera))
                            }
                            AddAttachmentButton(title: L10n.Attachment.photos, icon: DS.Icon.icImage.swiftUIImage) {
                                action(.attachmentOptionChosen(.photos))
                            }
                        }
                        Section {
                            AddAttachmentButton(title: L10n.Attachment.sketch, icon: DS.Icon.icPencil.swiftUIImage) {
                                action(.attachmentOptionChosen(.sketch))
                            }
                        }
                    },
                    label: {
                        ComposerToggleButton(
                            icon: DS.Icon.icPlus.swiftUIImage,
                            iconColor: iconColor,
                            isDisabled: areButtonsDisabled,
                            action: {}
                        )
                    }
                )

                if isCreateImageEnabled {
                    ImageModeButton(action: { action(.exitImageModeTapped) })
                } else {
                    ComposerToggleButton(
                        icon: DS.Icon.icSliders.swiftUIImage,
                        iconColor: iconColor,
                        isDisabled: areButtonsDisabled,
                        action: { action(.toolsTapped) }
                    )
                }
            }
            Spacer()
            HStack(spacing: DS.Spacing.standard) {
                SelectModelButton(
                    model: model,
                    color: iconColor,
                    isDisabled: areButtonsDisabled,
                    action: { action(.modelSelectionTapped) }
                )
                ComposerToggleButton(
                    icon: DS.Icon.icMicrophone.swiftUIImage,
                    iconColor: iconColor,
                    isDisabled: areButtonsDisabled,
                    action: { action(.microphoneTapped) }
                )
            }
        }
    }
}

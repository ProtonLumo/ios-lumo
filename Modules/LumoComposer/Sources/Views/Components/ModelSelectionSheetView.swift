import LumoDesignSystem
import SwiftUI

struct ModelSelectionSheetView: View {
    enum Action {
        case modelSelected(WebComposerState.Model)
        case closeTapped
    }

    let selectedModel: WebComposerState.Model
    let action: (Action) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            SheetHeaderView(title: L10n.ModelSelectionSheet.title) {
                action(.closeTapped)
            }

            VStack(spacing: .zero) {
                Button {
                    action(.modelSelected(.auto))
                } label: {
                    ModelRowView(model: .auto, isSelected: selectedModel == .auto)
                }
                .buttonStyle(.plain)

                Button {
                    action(.modelSelected(.fast))
                } label: {
                    ModelRowView(model: .fast, isSelected: selectedModel == .fast)
                }
                .buttonStyle(.plain)

                Button {
                    action(.modelSelected(.thinking))
                } label: {
                    ModelRowView(model: .thinking, isSelected: selectedModel == .thinking)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, DS.Spacing.large)
        }
    }
}

private struct ModelRowView: View {
    let model: WebComposerState.Model
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.medium) {
            icon
                .square(size: 20)
                .foregroundStyle(DS.Color.Text.norm)
                .padding(.vertical, DS.Spacing.tiny)
                .padding(.horizontal, DS.Spacing.standard)

            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                HStack(spacing: DS.Spacing.compact) {
                    Text(title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(DS.Color.Text.norm)
                    if model == .thinking {
                        DS.Icon.lumoPlus.swiftUIImage
                            .font(.subheadline.weight(.semibold))
                    }
                }
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.Text.hint)
            }

            Spacer()

            if isSelected {
                DS.Icon.icCheckmark.swiftUIImage
                    .foregroundStyle(DS.Color.Text.norm)
            }
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.medium)
    }

    private var icon: Image {
        switch model {
        case .auto: DS.Icon.icDiamond.swiftUIImage
        case .fast: DS.Icon.icBolt.swiftUIImage
        case .thinking: DS.Icon.icLightbulb.swiftUIImage
        }
    }

    private var title: LocalizedStringResource {
        switch model {
        case .auto: L10n.ModelSelectionSheet.autoTitle
        case .fast: L10n.ModelSelectionSheet.fastTitle
        case .thinking: L10n.ModelSelectionSheet.thinkingTitle
        }
    }

    private var subtitle: LocalizedStringResource {
        switch model {
        case .auto: L10n.ModelSelectionSheet.autoSubtitle
        case .fast: L10n.ModelSelectionSheet.fastSubtitle
        case .thinking: L10n.ModelSelectionSheet.thinkingSubtitle
        }
    }
}

#if DEBUG
    #Preview {
        VStack {
            ModelSelectionSheetView(selectedModel: .auto, action: { _ in })
            ModelSelectionSheetView(selectedModel: .thinking, action: { _ in })
        }
    }
#endif

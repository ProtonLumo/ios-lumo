import LumoDesignSystem
import SwiftUI

struct ToolsSheetView: View {
    enum Action {
        case createImageTapped
        case webSearchToggled
        case closeTapped
    }

    let isWebSearchEnabled: Bool
    let action: (Action) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            SheetHeaderView(title: L10n.ToolsSheet.title) {
                action(.closeTapped)
            }

            VStack(spacing: .zero) {
                Button(
                    action: { action(.createImageTapped) },
                    label: {
                        ToolItem<EmptyView>(
                            icon: DS.Icon.icPalette.swiftUIImage,
                            text: L10n.ToolsSheet.createImage,
                            trailingElement: .none
                        )
                    }
                )
                .buttonStyle(.plain)

                ToolItem(
                    icon: DS.Icon.icGlobe.swiftUIImage,
                    text: L10n.ToolsSheet.webSearch,
                    trailingElement: {
                        Toggle(
                            String(""),
                            isOn: .init(
                                get: { isWebSearchEnabled },
                                set: { _ in action(.webSearchToggled) }
                            )
                        )
                        .labelsHidden()
                        .tint(DS.Color.primary)
                    }
                )
            }
            .padding(.top, DS.Spacing.medium)
        }
    }
}

#if DEBUG
    #Preview {
        VStack {
            ToolsSheetView(isWebSearchEnabled: false, action: { _ in })
            ToolsSheetView(isWebSearchEnabled: true, action: { _ in })
        }
    }
#endif

import Lottie
import LumoDesignSystem
import SwiftUI

public struct ComposerScreen: View {
    @Environment(\.colorScheme) var colorScheme

    private let isSnapshotMode: Bool

    public init(isSnapshotMode: Bool = false) {
        self.isSnapshotMode = isSnapshotMode
    }

    // MARK: - View

    public var body: some View {
        ZStack {
            catPlaceholder()
                .offset(y: -DS.Spacing.extraLarge)

            VStack(spacing: DS.Spacing.medium) {
                logoPlaceholder()
                Spacer()
                TermsAndPrivacyText()
                ComposerView(
                    text: .constant(""),
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: false,
                    actionButton: .none,
                    action: { _ in }
                )
                .padding(.horizontal, DS.Spacing.tiny)
                .padding(.bottom, DS.Spacing.standard)
            }
        }
    }

    private func logoPlaceholder() -> some View {
        HStack(spacing: .zero) {
            DS.Icon.lumoLogo.swiftUIImage
                .padding(.top, DS.Spacing.large)
                .padding(.leading, 58)
                .foregroundStyle(DS.Color.Text.norm)
            Spacer()
        }
    }

    private func catPlaceholder() -> some View {
        VStack(spacing: -DS.Spacing.standard) {
            Group {
                if isSnapshotMode {
                    LottieView(animation: animation)
                        .snapshotMode(at: 0.2)
                } else {
                    LottieView(animation: animation)
                        .playbackInLoopMode()
                }
            }
            .frame(width: 220, height: 201)
            ComposerWelcomeText()
        }
    }

    // MARK: - Private

    private var animation: LottieAnimation {
        let darkItem = LottieAnimations.LumoCat.dark
        let lightItem = LottieAnimations.LumoCat.light

        return colorScheme == .dark ? darkItem : lightItem
    }
}

#if DEBUG
    #Preview {
        ComposerScreen()
    }
#endif

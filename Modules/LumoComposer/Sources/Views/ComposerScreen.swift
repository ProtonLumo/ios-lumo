import Lottie
import LumoDesignSystem
import SwiftUI

public struct ComposerScreen: View {
    @Environment(\.colorScheme) var colorScheme

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
                    files: [],
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
    }

    // MARK: - Private

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
        ComposerScreen()
    }
#endif

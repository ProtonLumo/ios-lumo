import Lottie

enum LottieAnimations {
    enum LumoCat {
        static let light: LottieAnimation = .named("lumo-cat").unsafelyUnwrapped
        static let dark: LottieAnimation = .named("lumo-cat-dark").unsafelyUnwrapped
    }

    static let lumoLoader: LottieAnimation = .named("lumo-loader").unsafelyUnwrapped
}

extension LottieView {
    func playbackInLoopMode() -> Self {
        playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
    }
}

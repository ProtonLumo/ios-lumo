import CoreFoundation
import Lottie

public enum LottieAnimations {
    public enum LumoCat {
        public static let light: LottieAnimation = .named("lumo-cat", bundle: .module).unsafelyUnwrapped
        public static let dark: LottieAnimation = .named("lumo-cat-dark", bundle: .module).unsafelyUnwrapped
    }

    public static let lumoLoader: LottieAnimation = .named("lumo-loader", bundle: .module).unsafelyUnwrapped
}

extension LottieView {
    public func playbackInLoopMode() -> Self {
        playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
    }

    /// For snapshot tests - pauses animation at a specific frame
    public func snapshotMode(at progress: AnimationProgressTime = 0.5) -> Self {
        playbackMode(.paused(at: .progress(progress)))
    }
}

import Foundation

public struct RecordingViewState: Equatable, Copying {
    public var transcription: String
    public var audioLevels: [CGFloat]
    public var duration: TimeInterval
    public var isOnDevice: Bool
}

extension RecordingViewState {
    static var initial: Self {
        .init(
            transcription: "",
            audioLevels: AudioLevelNormalizer.initialLevels,
            duration: .zero,
            isOnDevice: false
        )
    }
}

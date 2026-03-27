import Foundation

struct RecordingViewState: Equatable, Copying {
    var transcription: String
    var audioLevels: [CGFloat]
    var duration: TimeInterval
    var isOnDevice: Bool
}

extension RecordingViewState {
    static var initial: Self {
        .init(
            transcription: "",
            audioLevels: Array(repeating: 0.1, count: 30),
            duration: .zero,
            isOnDevice: false
        )
    }
}

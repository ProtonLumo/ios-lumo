import AVFoundation

protocol AudioEngine {
    func installInputTap(
        bufferSize: AVAudioFrameCount,
        block: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    )
    /// Prepares resources and starts the engine.
    func start() throws
    /// Removes the input tap and stops the engine.
    func stop()
}

final class AVAudioEngineAdapter: AudioEngine {
    private let engine = AVAudioEngine()

    func installInputTap(
        bufferSize: AVAudioFrameCount,
        block: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    ) {
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, _ in
            block(buffer)
        }
    }

    func start() throws {
        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }
}

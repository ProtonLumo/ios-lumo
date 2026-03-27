import AVFoundation

protocol AudioEngine {
    var isRunning: Bool { get }

    func installInputTap(
        bufferSize: AVAudioFrameCount,
        block: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    )
    func removeInputTap()
    func prepare()
    func start() throws
    func stop()
}

final class AVAudioEngineAdapter: AudioEngine {
    private let engine = AVAudioEngine()

    // MARK: - AudioEngine

    var isRunning: Bool {
        engine.isRunning
    }

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

    func removeInputTap() {
        engine.inputNode.removeTap(onBus: 0)
    }

    func prepare() {
        engine.prepare()
    }

    func start() throws {
        try engine.start()
    }

    func stop() {
        engine.stop()
    }
}

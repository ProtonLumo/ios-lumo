import AVFoundation

@testable import LumoComposer

final class AudioEngineSpy: AudioEngine {
    var stubbedStartError: (any Error)?

    var prepareCalled = false
    var startCalled = false
    var stopCalled = false
    private(set) var tapBlock: (@Sendable (AVAudioPCMBuffer) -> Void)?

    // MARK: - AudioEngine

    var isRunning = false

    func installInputTap(
        bufferSize: AVAudioFrameCount,
        block: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    ) {
        tapBlock = block
    }

    func removeInputTap() {
        tapBlock = nil
    }

    func prepare() {
        prepareCalled = true
    }

    func start() throws {
        if let error = stubbedStartError {
            throw error
        }

        isRunning = true
        startCalled = true
    }

    func stop() {
        isRunning = false
        stopCalled = true
    }

    // MARK: - Test helpers

    func simulateTapBlock(_ buffer: AVAudioPCMBuffer) {
        tapBlock?(buffer)
    }
}

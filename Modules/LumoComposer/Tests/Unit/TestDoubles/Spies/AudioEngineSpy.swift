import AVFoundation

@testable import LumoComposer

final class AudioEngineSpy: AudioEngine {
    var stubbedStartError: (any Error)?

    private(set) var startCalled = false
    private(set) var stopCalled = false
    private(set) var tapBlock: (@Sendable (AVAudioPCMBuffer) -> Void)?

    // MARK: - AudioEngine

    func installInputTap(
        bufferSize: AVAudioFrameCount,
        block: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    ) {
        tapBlock = block
    }

    func start() throws {
        if let error = stubbedStartError {
            throw error
        }

        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    // MARK: - Spy interface

    func simulateTapBlock(_ buffer: AVAudioPCMBuffer) {
        tapBlock?(buffer)
    }
}

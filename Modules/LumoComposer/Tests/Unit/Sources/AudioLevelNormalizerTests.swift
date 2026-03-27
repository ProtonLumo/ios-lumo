import AVFoundation
import Testing

@testable import LumoComposer

struct AudioLevelNormalizerTests {
    // MARK: - initialLevels

    @Test
    func initialLevels_has30Bars() {
        #expect(AudioLevelNormalizer.initialLevels.count == 30)
    }

    @Test
    func initialLevels_allBarsAre01() {
        let allMatch = AudioLevelNormalizer.initialLevels.allSatisfy { $0 == 0.1 }
        #expect(allMatch)
    }

    // MARK: - normalizedLevel

    @Test
    func normalizedLevel_silentBuffer_returnsZero() {
        let buffer = makeBuffer(amplitude: 0.0)
        let level = AudioLevelNormalizer.normalizedLevel(from: buffer)
        #expect(level == 0)
    }

    @Test
    func normalizedLevel_emptyBuffer_returnsZero() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 0
        let level = AudioLevelNormalizer.normalizedLevel(from: buffer)
        #expect(level == 0)
    }

    @Test
    func normalizedLevel_fullAmplitude_returnsOne() {
        // Amplitude 1.0 → RMS = 1.0 → 0 dB → normalized = 1.0 → pow(1.0, 0.7) = 1.0
        let buffer = makeBuffer(amplitude: 1.0)
        let level = AudioLevelNormalizer.normalizedLevel(from: buffer)
        #expect(level == 1.0)
    }

    @Test
    func normalizedLevel_moderateAmplitude_returnsBetweenZeroAndOne() {
        let buffer = makeBuffer(amplitude: 0.1)
        let level = AudioLevelNormalizer.normalizedLevel(from: buffer)
        #expect(level > 0)
        #expect(level < 1)
    }

    @Test
    func normalizedLevel_louderBuffer_returnsHigherValue() {
        let quiet = AudioLevelNormalizer.normalizedLevel(from: makeBuffer(amplitude: 0.01))
        let loud = AudioLevelNormalizer.normalizedLevel(from: makeBuffer(amplitude: 0.5))
        #expect(loud > quiet)
    }

    @Test
    func normalizedLevel_veryQuietBuffer_clampedToZero() {
        // Amplitude 0.0001 → RMS ≈ 0.0001 → -80 dB → below -60 dB floor → 0
        let buffer = makeBuffer(amplitude: 0.0001)
        let level = AudioLevelNormalizer.normalizedLevel(from: buffer)
        #expect(level == 0)
    }

    // MARK: - smoothed

    @Test
    func smoothed_shiftsArrayLeftAndAppendsNewValue() {
        let levels: [CGFloat] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let updated = AudioLevelNormalizer.smoothed(levels: levels, newValue: 0.8)

        #expect(updated.count == 5)
        #expect(updated[0] == levels[1])
        #expect(updated[1] == levels[2])
        #expect(updated[2] == levels[3])
        #expect(updated[3] == levels[4])
    }

    @Test
    func smoothed_preservesArrayCount() {
        let levels = AudioLevelNormalizer.initialLevels
        let updated = AudioLevelNormalizer.smoothed(levels: levels, newValue: 0.5)
        #expect(updated.count == AudioLevelNormalizer.barCount)
    }

    @Test
    func smoothed_appliesSmoothingFormula() {
        let levels: [CGFloat] = [0.1, 0.1, 0.1, 0.1, 0.5]
        let updated = AudioLevelNormalizer.smoothed(
            levels: levels,
            newValue: 1.0,
            smoothingFactor: 0.3
        )
        // smoothed = 0.5 * 0.3 + 1.0 * 0.7 = 0.85
        // final = min(1.0, 0.85 * 1.2) = min(1.0, 1.02) = 1.0
        #expect(updated.last == 1.0)
    }

    @Test
    func smoothed_clampsMinimumTo005() {
        let levels: [CGFloat] = [0.05, 0.05, 0.05, 0.05, 0.05]
        let updated = AudioLevelNormalizer.smoothed(
            levels: levels,
            newValue: 0.0,
            smoothingFactor: 0.3
        )
        // smoothed = 0.05 * 0.3 + 0.0 * 0.7 = 0.015
        // final = max(0.05, 0.015 * 1.2) = max(0.05, 0.018) = 0.05
        #expect(updated.last == 0.05)
    }

    @Test
    func smoothed_clampsMaximumTo1() {
        let levels: [CGFloat] = [1.0, 1.0, 1.0, 1.0, 1.0]
        let updated = AudioLevelNormalizer.smoothed(
            levels: levels,
            newValue: 1.0,
            smoothingFactor: 0.3
        )
        // smoothed = 1.0 * 0.3 + 1.0 * 0.7 = 1.0
        // final = min(1.0, 1.0 * 1.2) = 1.0
        #expect(updated.last == 1.0)
    }

    @Test
    func smoothed_higherSmoothingFactor_weighsPreviousValueMore() {
        let levels: [CGFloat] = [0.1, 0.1, 0.1, 0.1, 0.8]
        let lowSmoothing = AudioLevelNormalizer.smoothed(levels: levels, newValue: 0.2, smoothingFactor: 0.1)
        let highSmoothing = AudioLevelNormalizer.smoothed(levels: levels, newValue: 0.2, smoothingFactor: 0.9)

        // High smoothing keeps more of previous (0.8), so result should be higher
        #expect(highSmoothing.last! > lowSmoothing.last!)
    }

    // MARK: - Helpers

    private func makeBuffer(amplitude: Float, frameCount: Int = 1024) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        let samples = buffer.floatChannelData!.pointee
        for i in 0..<frameCount {
            samples[i] = amplitude
        }
        return buffer
    }
}

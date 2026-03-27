import AVFoundation

/// Converts raw audio buffers into a visual waveform (array of bar heights).
///
/// Pipeline: PCM samples → RMS loudness → decibels → 0–1 normalized → smoothed bar array.
enum AudioLevelNormalizer {
    static let barCount = 30
    static let initialLevels: [CGFloat] = Array(repeating: 0.1, count: barCount)

    /// Silence floor in decibels. Anything quieter reads as 0.
    private static let silenceFloorDb: Float = -60.0

    /// Exponent for the visual curve. Values < 1 boost quiet sounds,
    /// making the waveform more responsive to speech.
    private static let visualCurveExponent: Float = 0.7

    // MARK: - Public

    /// Extracts a normalized loudness value (0.0–1.0) from a PCM audio buffer.
    /// Pure function — safe to call from any thread.
    static func normalizedLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let samples = buffer.floatChannelData?.pointee, buffer.frameLength > 0 else {
            return 0
        }

        let rms = rootMeanSquare(samples: samples, count: Int(buffer.frameLength))
        let db = decibels(from: rms)
        let normalized = normalize(db: db, floor: silenceFloorDb)
        return CGFloat(powf(normalized, visualCurveExponent))
    }

    /// Smooths a new level value with the previous bar and shifts the array left (scrolling waveform).
    static func smoothed(
        levels: [CGFloat],
        newValue: CGFloat,
        smoothingFactor: CGFloat = 0.3
    ) -> [CGFloat] {
        let previousValue = levels.last ?? 0.1
        let blended = previousValue * smoothingFactor + newValue * (1 - smoothingFactor)
        let clamped = max(0.05, min(1.0, blended * 1.2))

        var updated = Array(levels.dropFirst())
        updated.append(clamped)
        return updated
    }

    // MARK: - Private

    /// Root Mean Square — standard measure of signal loudness.
    /// Squares each sample (removes sign), averages, then takes the square root.
    private static func rootMeanSquare(samples: UnsafeMutablePointer<Float>, count: Int) -> Float {
        var sumOfSquares: Float = 0
        for i in 0..<count {
            let sample = samples[i]
            sumOfSquares += sample * sample
        }
        return sqrt(sumOfSquares / Float(count))
    }

    /// Converts linear amplitude to decibels: `20 * log10(amplitude)`.
    /// Returns -100 dB for silence (amplitude ≤ 0).
    private static func decibels(from amplitude: Float) -> Float {
        amplitude > 0 ? 20 * log10(amplitude) : -100.0
    }

    /// Maps a dB value to 0.0–1.0, where `floor` dB = 0 and 0 dB = 1.
    private static func normalize(db: Float, floor: Float) -> Float {
        max(0, min(1, (db - floor) / (0 - floor)))
    }
}

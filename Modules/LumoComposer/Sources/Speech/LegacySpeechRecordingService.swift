import AVFoundation
import Speech

@MainActor
final class LegacySpeechRecordingService: SpeechRecordingServiceProtocol {
    private(set) var updates: AsyncStream<SpeechRecordingUpdate> = AsyncStream { $0.finish() }

    private var continuation: AsyncStream<SpeechRecordingUpdate>.Continuation?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var audioLevels: [CGFloat] = Array(repeating: 0.1, count: barCount)

    private static let barCount = 30

    init() {
        let locale = Locale.current
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        if speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }

        speechRecognizer?.defaultTaskHint = .dictation
    }

    // MARK: - SpeechRecordingServiceProtocol

    func requestPermissions() async -> SpeechPermissionResult {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            return speechStatus == .restricted ? .restricted : .denied
        }

        let micGranted = await AVAudioApplication.requestRecordPermission()

        return micGranted ? .granted : .denied
    }

    func startRecording() async throws {
        // Finish old stream — consumer holding old reference gets .finished
        continuation?.finish()

        let (stream, cont) = AsyncStream<SpeechRecordingUpdate>.makeStream()
        updates = stream
        continuation = cont
        audioLevels = Array(repeating: 0.1, count: Self.barCount)

        // Stop any running engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Audio session setup
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            try? session.setPreferredSampleRate(16000.0)
            try? session.setPreferredIOBufferDuration(0.01)
        } catch {
            continuation?.yield(.failed(.audioSessionFailed(error)))
            continuation?.finish()
            continuation = nil
            throw error
        }

        // Recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        recognitionRequest = request

        // Emit on-device status
        let supportsOnDevice = speechRecognizer?.supportsOnDeviceRecognition ?? false
        continuation?.yield(.isOnDeviceChanged(supportsOnDevice))

        // Recognition task
        guard let recognizer = speechRecognizer else {
            continuation?
                .yield(
                    .failed(
                        .recognitionFailed(
                            NSError(
                                domain: "SpeechRecordingService", code: -1,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "Speech recognizer unavailable"
                                ])
                        )))
            continuation?.finish()
            continuation = nil
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                self?.handleRecognitionResult(result, error: error)
            }
        }

        // Audio engine tap
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            // append() is thread-safe — designed to be called from the audio tap
            self?.recognitionRequest?.append(buffer)

            // Pure computation on the audio thread — no MainActor state accessed
            let normalizedLevel = Self.computeNormalizedLevel(from: buffer)

            // Dispatch result to MainActor for state update + emission
            Task { @MainActor [weak self] in
                self?.updateAudioLevels(with: normalizedLevel)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() async {
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        tearDown()
    }

    func cancel() {
        recognitionTask?.cancel()
        tearDown()
    }

    // MARK: - Pure computation (runs on audio thread)

    /// Computes a normalized audio level (0.0–1.0) from a PCM buffer.
    /// Pure function — no shared state accessed, safe to call from any thread.
    private static func computeNormalizedLevel(from buffer: AVAudioPCMBuffer) -> CGFloat {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelDataValue = channelData.pointee
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }

        var sum: Float = 0
        for i in 0..<frameCount {
            let sample = channelDataValue[i]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameCount))

        var db: Float = -100.0
        if rms > 0 {
            db = 20 * log10(rms)
        }

        let minDb: Float = -60.0
        var normalizedValue = max(0.0, min(1.0, (db - minDb) / (0 - minDb)))
        normalizedValue = powf(normalizedValue, 0.7)

        return CGFloat(normalizedValue)
    }

    // MARK: - MainActor-isolated state updates

    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            continuation?.yield(.transcriptionUpdated(result.bestTranscription.formattedString))
        }

        guard let error else { return }

        let nsError = error as NSError

        // Cancelled — normal lifecycle, ignore
        if nsError.code == 1 { return }

        // kLSRErrorDomain 201 — Siri/Dictation disabled in Settings
        if nsError.domain == "kLSRErrorDomain" && nsError.code == 201 {
            continuation?.yield(.failed(.permissionDenied))
            return
        }

        // kAFAssistantErrorDomain transient errors — ignore
        if nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 1110 || nsError.code == 1107) {
            return
        }

        // Unknown error — only emit if no result was delivered
        if result == nil {
            continuation?.yield(.failed(.recognitionFailed(error)))
        }
    }

    private func updateAudioLevels(with currentValue: CGFloat) {
        let lastValue = audioLevels.last ?? 0.1

        let smoothingFactor: CGFloat = 0.3
        let smoothedValue = lastValue * smoothingFactor + currentValue * (1 - smoothingFactor)
        let finalValue = max(0.05, min(1.0, smoothedValue * 1.2))

        // Shift left
        for i in 0..<(audioLevels.count - 1) {
            audioLevels[i] = audioLevels[i + 1]
        }
        audioLevels[audioLevels.count - 1] = finalValue

        continuation?.yield(.audioLevelsUpdated(audioLevels))
    }

    private func tearDown() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest = nil
        recognitionTask = nil

        continuation?.finish()
        continuation = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

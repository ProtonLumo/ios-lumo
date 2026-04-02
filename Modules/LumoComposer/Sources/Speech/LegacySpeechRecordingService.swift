import AVFoundation
import Speech

extension AVAudioFrameCount {
    /// Standard buffer size for speech recognition audio tap.
    /// 4096 frames at 16kHz ≈ 256ms — balances latency vs CPU overhead.
    static let speechRecognition: AVAudioFrameCount = 4_096
}

@MainActor
final class LegacySpeechRecordingService: SpeechRecordingServiceProtocol {
    private(set) var updates: AsyncStream<SpeechRecordingUpdate> = AsyncStream { $0.finish() }

    private var continuation: AsyncStream<SpeechRecordingUpdate>.Continuation?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: (any SpeechRecognitionTask)?
    private var audioLevels: [CGFloat] = AudioLevelNormalizer.initialLevels

    private let audioSession: AudioSession
    private let audioApplication: AudioApplication.Type
    private let speechAuthorization: SpeechAuthorizationProviding.Type
    private let speechRecognizer: SpeechRecognizerProviding?
    private let audioEngine: AudioEngine

    typealias SpeechRecognizerFactory = @MainActor (Locale) -> SpeechRecognizerProviding?

    init(
        audioSession: AudioSession = AVAudioSession.sharedInstance(),
        audioApplication: AudioApplication.Type = AVAudioApplication.self,
        speechAuthorization: SpeechAuthorizationProviding.Type = SFSpeechRecognizer.self,
        speechRecognizerFactory: SpeechRecognizerFactory = SFSpeechRecognizerAdapterFactory.make,
        audioEngine: AudioEngine = AVAudioEngineAdapter()
    ) {
        self.audioSession = audioSession
        self.audioApplication = audioApplication
        self.speechAuthorization = speechAuthorization
        self.audioEngine = audioEngine
        self.speechRecognizer = speechRecognizerFactory(Locale.current)
    }

    // MARK: - SpeechRecordingServiceProtocol

    func requestPermissions() async -> SpeechPermissionResult {
        let speechStatus = await withCheckedContinuation { continuation in
            speechAuthorization.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            return speechStatus == .restricted ? .restricted : .denied
        }

        let microphoneGranted = await audioApplication.requestRecordPermission()
        return microphoneGranted ? .granted : .denied
    }

    func startRecording() async throws {
        continuation?.finish()

        let (stream, cont) = AsyncStream<SpeechRecordingUpdate>.makeStream()
        updates = stream
        continuation = cont
        audioLevels = AudioLevelNormalizer.initialLevels

        audioEngine.stop()

        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try? audioSession.setPreferredSampleRate(16000.0)
            try? audioSession.setPreferredIOBufferDuration(0.01)
        } catch {
            continuation?.yield(.failed(.audioSessionFailed(error)))
            continuation?.finish()
            continuation = nil
            throw error
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        recognitionRequest = request

        let supportsOnDevice = speechRecognizer?.supportsOnDeviceRecognition ?? false
        continuation?.yield(.isOnDeviceChanged(supportsOnDevice))

        guard let recognizer = speechRecognizer else {
            continuation?.yield(.failed(.recognizerUnavailable))
            tearDown()
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] transcription, error in
            Task { @MainActor [weak self] in
                self?.handleRecognitionResult(transcription: transcription, error: error)
            }
        }

        // Audio engine tap — capture request to call append from audio thread
        // https://developer.apple.com/documentation/speech/recognizing-speech-in-live-audio
        audioEngine.installInputTap(bufferSize: .speechRecognition) { [weak self, request] buffer in
            request.append(buffer)

            let normalizedLevel = AudioLevelNormalizer.normalizedLevel(from: buffer)

            Task { @MainActor [weak self] in
                self?.updateAudioLevels(with: normalizedLevel)
            }
        }

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

    // MARK: - Private

    private func handleRecognitionResult(transcription: String?, error: Error?) {
        if let transcription {
            continuation?.yield(.transcriptionUpdated(transcription))
        }

        guard let error else { return }

        switch RecognitionErrorMapper.action(for: error) {
        case .none where transcription != nil:
            break
        case .ignore:
            break
        case .permissionDenied:
            continuation?.yield(.failed(.permissionDenied))
        case .none:
            continuation?.yield(.failed(.recognitionFailed(error)))
        }
    }

    private func updateAudioLevels(with currentValue: CGFloat) {
        audioLevels = AudioLevelNormalizer.smoothed(levels: audioLevels, newValue: currentValue)
        continuation?.yield(.audioLevelsUpdated(audioLevels))
    }

    private func tearDown() {
        audioEngine.stop()

        recognitionRequest = nil
        recognitionTask = nil

        continuation?.finish()
        continuation = nil

        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

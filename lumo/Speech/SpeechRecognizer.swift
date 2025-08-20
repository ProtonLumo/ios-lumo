import Foundation
import Speech
import SwiftUI
import AVFoundation

class SpeechRecognizer: ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var taskHasBeenCancelled = false
    private var audioLevelTimer: Timer?
    
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var audioLevels: [CGFloat] = Array(repeating: 0.1, count: 30)
    @Published var supportsOnDeviceRecognition = false
    @Published var showingPermissionAlert = false
    
    init() {
        let locale = Locale.current
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            Logger.shared.log("Initial audio session configuration set")
        } catch {
            Logger.shared.log("Could not configure initial audio session: \(error)")
        }
        
        Logger.shared.log("SpeechRecognizer initialized - permissions will be requested when needed")
        
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        if let recognizer = speechRecognizer {
            Logger.shared.log("Speech recognizer created for locale: \(locale.identifier)")
            
            if recognizer.supportsOnDeviceRecognition {
                recognizer.supportsOnDeviceRecognition = true
                supportsOnDeviceRecognition = true
                Logger.shared.log("On-device speech recognition is supported and enabled")
            } else {
                recognizer.supportsOnDeviceRecognition = false
                supportsOnDeviceRecognition = false
                Logger.shared.log("On-device speech recognition is NOT supported, using server-based")
            }
            
            recognizer.defaultTaskHint = .dictation
        }
        
        if speechRecognizer == nil {
            Logger.shared.log("Speech recognition not available for locale: \(locale.identifier), falling back to English")
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            
            if let recognizer = speechRecognizer {
                if recognizer.supportsOnDeviceRecognition {
                    recognizer.supportsOnDeviceRecognition = true
                    supportsOnDeviceRecognition = true
                    Logger.shared.log("On-device speech recognition is supported for English fallback")
                } else {
                    recognizer.supportsOnDeviceRecognition = false
                    supportsOnDeviceRecognition = false
                    Logger.shared.log("On-device speech recognition is NOT supported for English fallback")
                }
                
                recognizer.defaultTaskHint = .dictation
            }
        }
    }
    
    func startRecording() {
        taskHasBeenCancelled = false
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.configureAudioSessionAndStartRecording()
        }
    }
    
    private func configureAudioSessionAndStartRecording() {
        assert(Thread.isMainThread, "Audio session configuration must happen on main thread")
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            Logger.shared.log("Setting up audio session for recording")
            
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, 
                                        options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            try? audioSession.setPreferredSampleRate(16000.0)
            try? audioSession.setPreferredIOBufferDuration(0.01)
            
            Logger.shared.log("Audio session setup succeeded")
        } catch {
            Logger.shared.log("Failed to set up audio session: \(error)")
            
            do {
                try audioSession.setCategory(.record, mode: .spokenAudio)
                try audioSession.setActive(true)
                Logger.shared.log("Fallback audio session configuration applied")
            } catch {
                Logger.shared.log("Fallback audio session also failed: \(error)")
                return
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.continueWithRecognitionSetup()
        }
    }
    
    private func continueWithRecognitionSetup() {
        if audioEngine.isRunning {
            Logger.shared.log("Audio engine is already running. Stopping first.")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        switch speechStatus {
        case .authorized:
            Logger.shared.log("Speech recognition already authorized, checking microphone permission")
            self.checkMicrophonePermissionAndContinue()
            
        case .notDetermined:
            Logger.shared.log("Requesting speech recognition authorization...")
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        Logger.shared.log("Speech recognition authorized by user")
                        self?.checkMicrophonePermissionAndContinue()
                    case .denied:
                        Logger.shared.log("Speech recognition authorization denied")
                    case .restricted:
                        Logger.shared.log("Speech recognition restricted")
                    case .notDetermined:
                        Logger.shared.log("Speech recognition still not determined")
                    @unknown default:
                        Logger.shared.log("Speech recognition unknown status")
                    }
                }
            }
            
        case .denied:
            Logger.shared.log("Speech recognition permission is denied - showing alert to user")
            DispatchQueue.main.async {
                self.showingPermissionAlert = true
            }
            
        case .restricted:
            Logger.shared.log("Speech recognition is restricted - showing alert to user")
            DispatchQueue.main.async {
                self.showingPermissionAlert = true
            }
            
        @unknown default:
            Logger.shared.log("Unknown speech recognition status")
        }
    }
    
    private func checkMicrophonePermissionAndContinue() {
        PermissionManager.shared.checkForPermissionChanges { [weak self] granted in
            if granted {
                Logger.shared.log("Microphone permission is granted - continuing with recording setup")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.setupRecognitionRequest()
                }
            } else {
                Logger.shared.log("Microphone permission is denied - showing alert to user")
                DispatchQueue.main.async {
                    self?.showingPermissionAlert = true
                }
            }
        }
    }
    
    private func setupRecognitionRequest() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            Logger.shared.log("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        if supportsOnDeviceRecognition {
            recognitionRequest.requiresOnDeviceRecognition = true
            Logger.shared.log("Using on-device speech recognition")
        } else {
            recognitionRequest.requiresOnDeviceRecognition = false
            Logger.shared.log("Using server-based speech recognition")
        }
        
        recognitionRequest.taskHint = .dictation
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self, !self.taskHasBeenCancelled else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                    Logger.shared.log("🎤 Transcribed text updated: '\(self.transcribedText)'")
                }
                
                if result.isFinal {
                    Logger.shared.log("Received final result but continuing recognition")
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                Logger.shared.log("❌ Recognition error: \(error), domain: \(nsError.domain), code: \(nsError.code)")
                
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
                    Logger.shared.log("⚠️ Local speech recognition error detected")
                    
                    if self.supportsOnDeviceRecognition {
                        Logger.shared.log("🔄 Switching to server-based recognition (first retry)")
                        
                        self.stopRecording()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.supportsOnDeviceRecognition = false
                            self.startRecording()
                        }
                    } else {
                        Logger.shared.log("❌ Server-based recognition also failed - stopping")
                        DispatchQueue.main.async {
                            self.stopRecording()
                        }
                    }
                    return
                }
                
                let errorCode = nsError.code
                if errorCode == SFSpeechRecognizerAuthorizationStatus.denied.rawValue ||
                   errorCode == SFSpeechRecognizerAuthorizationStatus.restricted.rawValue {
                    Logger.shared.log("❌ Fatal speech recognition error - stopping")
                    self.stopRecording()
                }
            }
        }
        
        let inputNode = audioEngine.inputNode
        let bufferSize: AVAudioFrameCount = 4096
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        startAudioLevelMonitoring(inputNode: inputNode)
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processAudioBufferForLevels(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.transcribedText = ""
                self.isRecording = true
            }
            Logger.shared.log("Audio engine started successfully")
        } catch {
            Logger.shared.log("Failed to start audio engine: \(error)")
        }
    }
    
    private func startAudioLevelMonitoring(inputNode: AVAudioNode) {
        DispatchQueue.main.async {
            self.audioLevels = Array(repeating: 0.1, count: 30)
        }
        
    }
    
    private func processAudioBufferForLevels(_ buffer: AVAudioPCMBuffer) {

        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frameCount = Int(buffer.frameLength)
        
        // Ensure we have valid frame count
        guard frameCount > 0 else { return }
        
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let lastValue = self.audioLevels.last ?? 0.1
            
            let smoothingFactor: CGFloat = 0.3
            let currentValue = CGFloat(normalizedValue)
            let smoothedValue = lastValue * smoothingFactor + currentValue * (1 - smoothingFactor)
            
            let finalValue = max(0.05, min(1.0, smoothedValue * 1.2))
            
            for i in 0..<(self.audioLevels.count - 1) {
                self.audioLevels[i] = self.audioLevels[i+1]
            }
            
            self.audioLevels[self.audioLevels.count-1] = finalValue
        }
    }
    
    func stopRecording() {
        taskHasBeenCancelled = true
        
        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.deactivateAudioSession()
            }
        } else {
            deactivateAudioSession()
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        Logger.shared.log("Recording stopped, final text: \(transcribedText)")
    }
    
    private func deactivateAudioSession() {
        assert(Thread.isMainThread, "Audio session deactivation must happen on main thread")
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            Logger.shared.log("Successfully deactivated audio session")
        } catch {
            Logger.shared.log("Error deactivating audio session: \(error)")
        }
    }
} 

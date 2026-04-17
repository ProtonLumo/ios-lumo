import AVFoundation

protocol AudioSession {
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool) throws
}

extension AVAudioSession: AudioSession {}

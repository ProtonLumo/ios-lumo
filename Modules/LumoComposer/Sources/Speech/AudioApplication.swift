import AVFoundation

protocol AudioApplication {
    static func requestRecordPermission() async -> Bool
}

extension AVAudioApplication: AudioApplication {}

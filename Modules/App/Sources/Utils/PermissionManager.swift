import AVFoundation
import Foundation

/// Manages permission states and tracks recent permission requests
class PermissionManager {
    /// Shared singleton instance
    static let shared = PermissionManager()

    /// Time when microphone permission was last requested
    private var lastMicrophonePermissionRequestTime: Date?

    /// Track that microphone permission was just requested
    func trackMicrophonePermissionRequest() {
        lastMicrophonePermissionRequestTime = Date()
        Logger.shared.log("Tracked microphone permission request at \(Date())")
    }

    /// Request microphone permission with tracking
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        // Mark that we're requesting permission
        trackMicrophonePermissionRequest()

        // Request on main thread
        DispatchQueue.main.async {
            AVAudioSession.sharedInstance()
                .requestRecordPermission { granted in
                    Logger.shared.log("Microphone permission \(granted ? "granted" : "denied")")

                    // Call completion on main thread
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
        }
    }

    /// Check if microphone permission has been granted since the app was last backgrounded
    /// This is useful for detecting when user has changed permissions in Settings
    func checkForPermissionChanges(completion: @escaping (Bool) -> Void) {
        let currentStatus = AVAudioSession.sharedInstance().recordPermission

        switch currentStatus {
        case .granted:
            Logger.shared.log("Microphone permission check: currently granted")
            completion(true)

        case .denied:
            Logger.shared.log("Microphone permission check: currently denied")
            completion(false)

        case .undetermined:
            Logger.shared.log("Microphone permission check: undetermined - requesting")
            // If undetermined, request permission
            requestMicrophonePermission(completion: completion)

        @unknown default:
            Logger.shared.log("Microphone permission check: unknown status")
            completion(false)
        }
    }
}

import Foundation
import AVFoundation

/// Manages permission states and tracks recent permission requests
class PermissionManager {
    /// Shared singleton instance
    static let shared = PermissionManager()
    
    /// Time when microphone permission was last requested
    private var lastMicrophonePermissionRequestTime: Date?
    
    /// Whether microphone permission was requested in the last 5 seconds
    var recentlyRequestedMicrophonePermission: Bool {
        guard let lastTime = lastMicrophonePermissionRequestTime else { return false }
        return Date().timeIntervalSince(lastTime) < 5.0 // Consider permissions "recent" for 5 seconds
    }
    
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
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Logger.shared.log("Microphone permission \(granted ? "granted" : "denied")")
                
                // Call completion on main thread
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    /// Check current microphone permission status with tracking
    func checkMicrophonePermission(onUndetermined: @escaping () -> Void, onGranted: @escaping () -> Void, onDenied: @escaping () -> Void) {
        let status = AVAudioSession.sharedInstance().recordPermission
        
        switch status {
        case .granted:
            Logger.shared.log("Microphone permission is already granted")
            onGranted()
            
        case .denied:
            Logger.shared.log("Microphone permission is denied")
            onDenied()
            
        case .undetermined:
            Logger.shared.log("Microphone permission is undetermined")
            onUndetermined()
            
        @unknown default:
            Logger.shared.log("Unknown microphone permission status")
            onUndetermined()
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
    
    /// Request permission with smart retry logic
    func requestWithRetryLogic(completion: @escaping (Bool) -> Void) {
        // First check current status to see if it's changed since last denial
        checkForPermissionChanges { granted in
            if granted {
                Logger.shared.log("Permission was granted (possibly changed in Settings)")
                completion(true)
            } else {
                // Still denied, but user wants to try again
                // For already-denied permissions, iOS won't show the dialog again
                // But we should still check in case they changed it manually
                Logger.shared.log("Permission still denied after retry attempt")
                completion(false)
            }
        }
    }
} 
import Foundation
import LumoCore
import UIKit

/// Manages background task execution to allow generation to complete
/// when the app moves to the background
///
/// Uses Apple's official `beginBackgroundTask` API which gives the app
/// ~30 seconds to finish ongoing work when backgrounded.
/// Reference: https://developer.apple.com/documentation/uikit/uiapplication/beginbackgroundtask(withname:expirationhandler:)
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var isTaskRunning = false

    private init() {}

    func beginBackgroundTask() {
        guard backgroundTaskID == .invalid else {
            Logger.shared.log("⚠️ Background task already running with ID: \(backgroundTaskID.rawValue)")
            return
        }

        Logger.shared.log("🔄 Starting background task for AI generation")

        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "LumoAIGeneration") { [weak self] in
            Logger.shared.log("⚠️ Background task expiring after ~30 seconds - cleaning up")
            self?.endBackgroundTask()
        }

        if backgroundTaskID != .invalid {
            isTaskRunning = true
            Logger.shared.log("✅ Background task started with ID: \(backgroundTaskID.rawValue)")

            // Log initial remaining time (safely handle infinity)
            let remaining = UIApplication.shared.backgroundTimeRemaining
            if remaining == .infinity {
                Logger.shared.log("⏱️ Background time: unlimited (app in foreground)")
            } else {
                Logger.shared.log("⏱️ Background time granted: ~\(String(format: "%.0f", remaining)) seconds")
            }
        } else {
            Logger.shared.log("❌ Failed to start background task - iOS may have denied it")
        }
    }

    func endBackgroundTask() {
        guard backgroundTaskID != .invalid else {
            Logger.shared.log("⚠️ No background task to end")
            return
        }

        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        isTaskRunning = false

        Logger.shared.log("✅ Background task ended successfully")
    }

    var hasActiveBackgroundTask: Bool {
        isTaskRunning && backgroundTaskID != .invalid
    }
}

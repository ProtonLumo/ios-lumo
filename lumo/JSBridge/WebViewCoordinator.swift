import Foundation
import WebKit
import Combine

/// Centralized coordinator for all WebView JavaScript operations
@MainActor
class WebViewCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var isReady = false
    @Published private(set) var lastError: JSBridgeError?
    
    // MARK: - Private Properties
    private weak var webView: WKWebView?
    private var pendingCommands: [JSCommand] = []
    private var executionQueue = DispatchQueue(label: "com.lumo.jsbridge", qos: .userInitiated)
    private let maxRetries = 3
    private let executionTimeout: TimeInterval = 10.0
    
    // MARK: - Initialization
    init() {}
    
    /// Configure the coordinator with a WebView
    func configure(with webView: WKWebView) {
        self.webView = webView
        self.isReady = false
    }
    
    /// Mark WebView as ready and process pending commands
    func markReady() {
        guard !isReady else { return }
        
        Logger.shared.log("✅ WebViewCoordinator: WebView is ready")
        isReady = true
        
        // Process any pending commands
        Task {
            await processPendingCommands()
        }
    }
    
    // MARK: - Command Execution
    
    /// Execute a JavaScript command
    /// - Parameters:
    ///   - command: The command to execute
    ///   - retryCount: Number of times to retry on failure (default: 0)
    /// - Returns: Result of the execution
    @discardableResult
    func execute(_ command: JSCommand, retryCount: Int = 0) async -> JSBridgeResult {
        Logger.shared.log("🚀 Executing JS command: \(command.description)")
        
        // If not ready, queue the command
        guard isReady, let webView = webView else {
            Logger.shared.log("⏳ WebView not ready, queueing command: \(command.description)")
            pendingCommands.append(command)
            return .failure(.webViewNotReady)
        }
        
        // Execute with timeout
        return await withTimeout(executionTimeout) {
            await self.executeCommand(command, in: webView, retryCount: retryCount)
        }
    }
    
    /// Execute multiple commands in sequence
    /// - Parameter commands: Array of commands to execute
    /// - Returns: Array of results
    func executeBatch(_ commands: [JSCommand]) async -> [JSBridgeResult] {
        var results: [JSBridgeResult] = []
        
        for command in commands {
            let result = await execute(command)
            results.append(result)
            
            // Stop on first failure for critical commands
            if case .failure = result, !command.isRetryable {
                break
            }
        }
        
        return results
    }
    
    /// Convenience method: Insert prompt
    func insertPrompt(_ text: String, editorType: JSCommand.EditorType = .tiptap) async -> JSBridgeResult {
        await execute(.insertPrompt(text: text, editorType: editorType), retryCount: 2)
    }
    
    /// Convenience method: Clear prompt
    func clearPrompt() async -> JSBridgeResult {
        await execute(.clearPrompt)
    }
    
    /// Convenience method: Get subscriptions
    func getSubscriptions() async -> JSBridgeResult {
        await execute(.getSubscriptions, retryCount: 1)
    }
    
    /// Convenience method: Read theme
    func readTheme() async -> JSBridgeResult {
        await execute(.readTheme)
    }
    
    /// Convenience method: Setup initial scripts
    func setupInitialScripts() async {
        let setupCommands: [JSCommand] = [
            .initialSetup,
            .setupMessageHandlers,
            .setupPromotionHandler,
            .setupVoiceEntry,
            .setupThemeListener
        ]
        
        _ = await executeBatch(setupCommands)
    }
    
    // MARK: - Private Methods
    
    private func executeCommand(_ command: JSCommand, in webView: WKWebView, retryCount: Int) async -> JSBridgeResult {
        let javascript = command.javascript
        
        // Ensure we're on main thread for WebView operations
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                webView.evaluateJavaScript(javascript) { result, error in
                    if let error = error {
                        Logger.shared.log("❌ JS Error for \(command.description): \(error.localizedDescription)")
                        
                        // Retry if allowed
                        if retryCount > 0 && command.isRetryable {
                            Logger.shared.log("🔄 Retrying command (attempts left: \(retryCount))")
                            Task {
                                let retryResult = await self.executeCommand(command, in: webView, retryCount: retryCount - 1)
                                continuation.resume(returning: retryResult)
                            }
                            return
                        }
                        
                        continuation.resume(returning: .failure(.executionFailed(error.localizedDescription)))
                        return
                    }
                    
                    // Parse result
                    let bridgeResult = self.parseResult(result, for: command)
                    
                    if case .success = bridgeResult {
                        Logger.shared.log("✅ JS Success for \(command.description)")
                    } else if case .failure(let error) = bridgeResult {
                        let errorDescription = error.errorDescription ?? "unknown"
                        Logger.shared.log("❌ JS Failed for \(command.description): \(errorDescription)")
                    }
                    
                    continuation.resume(returning: bridgeResult)
                }
            }
        }
    }
    
    private func parseResult(_ result: Any?, for command: JSCommand) -> JSBridgeResult {
        // Handle void returns (like simulateGarbageCollection)
        guard let result = result else {
            return .success(nil)
        }
        
        // Try to parse as JSResponse dictionary
        if let dict = result as? [String: Any] {
            if let success = dict["success"] as? Bool {
                if success {
                    return .success(dict["data"] ?? dict)
                } else {
                    let reason = dict["reason"] as? String ?? "Unknown error"
                    return .failure(.executionFailed(reason))
                }
            }
        }
        
        // Return raw result
        return .success(result)
    }
    
    private func processPendingCommands() async {
        guard !pendingCommands.isEmpty else { return }
        
        Logger.shared.log("📦 Processing \(pendingCommands.count) pending command(s)")
        let commands = pendingCommands
        pendingCommands.removeAll()
        
        for command in commands {
            await execute(command)
        }
    }
    
    /// Execute with timeout
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async -> T) async -> T {
        await withTaskGroup(of: T?.self) { group in
            // Add the main operation
            group.addTask {
                await operation()
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            
            // Return first result
            if let result = await group.next() {
                group.cancelAll()
                if let value = result {
                    return value
                }
            }
            
            // Timeout occurred - return failure if T is JSBridgeResult
            if T.self == JSBridgeResult.self {
                return JSBridgeResult.failure(.timeout) as! T
            }
            
            fatalError("Timeout handling not implemented for type \(T.self)")
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        Logger.shared.log("🧹 Cleaning up WebViewCoordinator")
        isReady = false
        pendingCommands.removeAll()
        webView = nil
    }
}

// MARK: - Global Convenience
extension WebViewCoordinator {
    /// Shared instance for global access (use with caution)
    static let shared = WebViewCoordinator()
}


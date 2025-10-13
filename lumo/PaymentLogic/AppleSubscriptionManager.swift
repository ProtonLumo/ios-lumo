import Foundation
import StoreKit
import UIKit

@MainActor
public class AppleSubscriptionManager: ObservableObject {
    
    public static let shared = AppleSubscriptionManager()
    
    @Published public private(set) var subscriptionStatuses: [String: Product.SubscriptionInfo.Status] = [:]
    @Published public private(set) var isLoading = false
    
    private var statusUpdateTask: Task<Void, Never>?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        statusUpdateTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Check if a subscription is an Apple subscription based on external field
    public func isAppleSubscription(_ subscription: CurrentSubscriptionResponse) -> Bool {
        return subscription.external == 1
    }
    
    /// Check if we have an Apple subscription that matches any of our app's products
    public func hasMatchingAppleSubscription(for subscription: CurrentSubscriptionResponse) -> Bool {
        // First check: server explicitly marks this as Apple subscription
        if isAppleSubscription(subscription) {
            // If server says it's Apple subscription, trust it even if we don't have local StoreKit data yet
            // This handles cases where StoreKit monitoring hasn't finished loading
            Logger.shared.log("Server indicates Apple subscription for '\(subscription.title)' (external=\(subscription.external ?? -1))")
            return true
        }
        
        // Second check: see if we have any active Apple subscriptions in StoreKit
        // This handles cases where server data might be delayed but we have local StoreKit data
        let hasLumoProducts = subscriptionStatuses.keys.contains { $0.hasPrefix("ioslumo_") }
        if hasLumoProducts {
            Logger.shared.log("Found active Lumo Apple subscriptions in StoreKit for '\(subscription.title)'")
            return true
        }
        
        Logger.shared.log("No Apple subscription match found for '\(subscription.title)' (external=\(subscription.external ?? -1), StoreKit products=\(subscriptionStatuses.count))")
        return false
    }
    
    /// Get the Apple product ID for a subscription if it exists in our tracked subscriptions
    public func getAppleProductId(for subscription: CurrentSubscriptionResponse) -> String? {
        guard isAppleSubscription(subscription) else { return nil }
        
        // Return the first product ID that matches our app prefix
        for productId in subscriptionStatuses.keys {
            if productId.hasPrefix("ioslumo_") {
                return productId
            }
        }
        
        return nil
    }
    
    /// Get the Apple subscription status for a given product ID
    public func getSubscriptionStatus(for productId: String) -> Product.SubscriptionInfo.Status? {
        return subscriptionStatuses[productId]
    }
    
    /// Check if a subscription is cancelled on Apple's side
    public func isSubscriptionCancelled(for productId: String) -> Bool {
        guard let status = subscriptionStatuses[productId] else { return false }
        
        switch status.state {
        case .expired, .revoked:
            return true
        case .subscribed:
            // Check if auto-renewal is disabled (user cancelled but still active)
            switch status.renewalInfo {
            case .verified(let renewalInfo):
                return renewalInfo.willAutoRenew == false
            case .unverified:
                return false
            }
        case .inGracePeriod, .inBillingRetryPeriod:
            return false
        default:
            return false
        }
    }
    
    /// Get cancellation date if subscription is cancelled
    public func getCancellationDate(for productId: String) -> Date? {
        guard let status = subscriptionStatuses[productId] else { return nil }
        
        switch status.state {
        case .expired, .revoked:
            switch status.transaction {
            case .verified(let transaction):
                return transaction.expirationDate
            case .unverified:
                return nil
            }
        case .subscribed:
            switch status.renewalInfo {
            case .verified(let renewalInfo):
                if renewalInfo.willAutoRenew == false {
                    // Return the current period end date
                    switch status.transaction {
                    case .verified(let transaction):
                        return transaction.expirationDate
                    case .unverified:
                        return nil
                    }
                }
                return nil
            case .unverified:
                return nil
            }
        default:
            return nil
        }
    }
    
    /// Check if there are any active Apple subscriptions
    public func hasActiveAppleSubscriptions() -> Bool {
        return !subscriptionStatuses.isEmpty
    }
    
    /// Open Apple's subscription management screen
    public func openSubscriptionManagement() {
        Task {
            // Check if we're in a sandbox environment
            let isSandbox = await checkIfSandboxEnvironment()
            
            if isSandbox {
                Logger.shared.log("Detected sandbox environment - AppStore.showManageSubscriptions may not work")
                await showSandboxSubscriptionManagement()
                return
            }
            
            do {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    Logger.shared.log("No window scene available for subscription management")
                    await openSettingsSubscriptionManagement()
                    return
                }
                
                Logger.shared.log("Opening Apple subscription management screen")
                Logger.shared.log("Current subscription statuses count: \(subscriptionStatuses.count)")
                
                // Log current subscription statuses for debugging
                for (productId, status) in subscriptionStatuses {
                    Logger.shared.log("Subscription \(productId): state=\(status.state)")
                }
                
                // Always try AppStore.showManageSubscriptions first, but have fallback ready
                try await AppStore.showManageSubscriptions(in: windowScene)
                Logger.shared.log("Successfully opened Apple subscription management")
            } catch {
                Logger.shared.log("AppStore.showManageSubscriptions failed: \(error)")
                Logger.shared.log("Falling back to Settings app")
                await openSettingsSubscriptionManagement()
            }
        }
    }
    
    /// Check if we're in a sandbox environment
    private func checkIfSandboxEnvironment() async -> Bool {
        // Check if we have any sandbox receipts or if we're in simulator
        #if targetEnvironment(simulator)
        return true
        #else
        // Check for sandbox receipt
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           appStoreReceiptURL.lastPathComponent == "sandboxReceipt" {
            return true
        }
        
        // Additional check: if we have subscription statuses but they're all from sandbox
        if !subscriptionStatuses.isEmpty {
            // In sandbox, transactions often have specific characteristics
            for (_, status) in subscriptionStatuses {
                switch status.transaction {
                case .verified(let transaction):
                    // Sandbox transactions often have environment indicators
                    if transaction.environment == .sandbox {
                        return true
                    }
                case .unverified:
                    continue
                }
            }
        }
        
        return false
        #endif
    }
    
    /// Show sandbox-specific subscription management
    private func showSandboxSubscriptionManagement() async {
        await MainActor.run {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                let alert = UIAlertController(
                    title: "Subscription Management",
                    message: "You're using a test version of the app. To manage your subscription:\n\n• Go to Settings > Apple ID > Subscriptions\n• Look for sandbox/test subscriptions\n• Or sign out and back in with your sandbox Apple ID",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                    Task {
                        await self.openSettingsURL()
                    }
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                rootViewController.present(alert, animated: true)
            } else {
                // No UI available, just open Settings directly
                Task {
                    await self.openSettingsURL()
                }
            }
        }
    }
    
    /// Fallback method to open Settings app subscription management
    private func openSettingsSubscriptionManagement() async {
        await MainActor.run {
            // Show a brief alert to inform the user
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                let alert = UIAlertController(
                    title: "Opening Settings",
                    message: "We'll open your device Settings where you can manage your Apple subscriptions.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    Task {
                        await self.openSettingsURL()
                    }
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                rootViewController.present(alert, animated: true)
            } else {
                // No UI available, just open Settings directly
                Task {
                    await self.openSettingsURL()
                }
            }
        }
    }
    
    /// Open Settings app with subscription management URL
    private func openSettingsURL() async {
        // Try different Settings URLs for subscription management
        let settingsURLs = [
            "App-prefs:APPLE_ACCOUNT&path=SUBSCRIPTIONS",
            "prefs:root=APPLE_ACCOUNT&path=SUBSCRIPTIONS",
            "App-prefs:root=APPLE_ACCOUNT",
            "prefs:root=APPLE_ACCOUNT"
        ]
        
        await MainActor.run {
            for urlString in settingsURLs {
                if let settingsURL = URL(string: urlString),
                   UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL)
                    Logger.shared.log("Opened Settings app with URL: \(urlString)")
                    return
                }
            }
            
            // Final fallback - just open Settings app
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
                Logger.shared.log("Opened Settings app as final fallback")
            } else {
                Logger.shared.log("Cannot open any subscription management interface")
            }
        }
    }
    
    /// Refresh subscription statuses
    public func refreshSubscriptionStatuses() {
        Task {
            await updateSubscriptionStatuses()
        }
    }
    
    /// Debug method to test subscription management (useful for development)
    public func debugSubscriptionManagement() {
        Task {
            Logger.shared.log("=== DEBUG: Subscription Management ===")
            Logger.shared.log("Subscription statuses count: \(subscriptionStatuses.count)")
            
            for (_, status) in subscriptionStatuses {
                
                switch status.transaction {
                case .verified(let transaction):
                    Logger.shared.log("  Environment: \(transaction.environment)")
                    Logger.shared.log("  Product ID: \(transaction.productID)")
                    Logger.shared.log("  Transaction ID: \(transaction.id)")
                case .unverified(_, let error):
                    Logger.shared.log("  Transaction unverified: \(error)")
                }
                
                switch status.renewalInfo {
                case .verified(let renewalInfo):
                    Logger.shared.log("  Will auto-renew: \(renewalInfo.willAutoRenew)")
                case .unverified(_, let error):
                    Logger.shared.log("  Renewal info unverified: \(error)")
                }
            }
            
            let isSandbox = await checkIfSandboxEnvironment()
            Logger.shared.log("Is sandbox environment: \(isSandbox)")
            Logger.shared.log("=== END DEBUG ===")
        }
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        statusUpdateTask = Task {
            
            // Log environment information
            #if targetEnvironment(simulator)
            Logger.shared.log("Running in iOS Simulator")
            #else
            Logger.shared.log("Running on physical device")
            #endif
            
            if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL {
                Logger.shared.log("Receipt filename: \(appStoreReceiptURL.lastPathComponent)")
            }
            
            await updateSubscriptionStatuses()
            
            // Monitor for subscription status updates
            for await _ in Transaction.updates {
                Logger.shared.log("Received transaction update")
                await updateSubscriptionStatuses()
            }
        }
    }
    
    private func updateSubscriptionStatuses() async {
        isLoading = true
        defer { isLoading = false }
        
        var newStatuses: [String: Product.SubscriptionInfo.Status] = [:]
        
        // Get all current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if let subscriptionStatus = await transaction.subscriptionStatus {
                    newStatuses[transaction.productID] = subscriptionStatus
                }
            case .unverified(_, let error):
                Logger.shared.log("Unverified transaction: \(error)")
            }
        }
        
        subscriptionStatuses = newStatuses
        Logger.shared.log("Updated Apple subscription statuses for \(newStatuses.count) products")
        
        // Debug: Log which products match our app prefix
        let lumoProducts = newStatuses.keys.filter { $0.hasPrefix("ioslumo_") }
        if !lumoProducts.isEmpty {
            Logger.shared.log("Found \(lumoProducts.count) Lumo Apple subscriptions: \(lumoProducts)")
        } else {
            Logger.shared.log("No Lumo Apple subscriptions found in current entitlements")
        }
    }
} 

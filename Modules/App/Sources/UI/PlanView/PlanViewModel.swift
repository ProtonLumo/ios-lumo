import Combine
import Foundation
import ProtonUIFoundations
import StoreKit

/// Represents a purchasable plan or free instance
@MainActor
public class PlanViewModel: ObservableObject, Identifiable {

    private struct Constants {
        static func footerText(renew: Int) -> String {

            let expirationText = String(localized: "current.plan.expiration")
            let renewalText = String(localized: "current.plan.renewal")

            return (renew == 0 ? expirationText : renewalText) + " " // Add space to separate the text and the date
        }
    }

    /// user visible description
    @Published var description: String
    /// user visible plan title
    @Published var title: String
    /// internal plan name
    @Published var name: String?
    /// List of progress bar entitlements
    @Published var progressEntitlements: [ProgressEntitlement]
    /// List of string entitlements offered
    @Published var descriptionEntitlements: [DescriptionEntitlement]
    /// pre-formatted price
    @Published var formattedPrice: String
    /// formatted cycle
    @Published var formattedPeriod: String

    @Published var isExpanded = false
    @Published var isAppleSubscription = false
    @Published var isAppleCancelled = false
    @Published var appleCancellationDate: Date?

    public var showProgressEntitlements: Bool {
        !progressEntitlements.isEmpty
    }

    public var renewFooter: AttributedString?
    public var isFreePlan: Bool
    
    // Apple subscription management
    public var showManageSubscriptionButton: Bool {
        isAppleSubscription && !isFreePlan
    }
    
    public var subscriptionStatusText: String? {
        if isAppleCancelled {
            if let cancellationDate = appleCancellationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let formattedDate = formatter.string(from: cancellationDate)
                return String(localized: "app.payment.cancelled.expires", comment: "Subscription cancelled with expiration date")
                    .replacingOccurrences(of: "%@", with: formattedDate)
            } else {
                return String(localized: "app.payment.cancelled")
            }
        }
        return nil
    }

    /// plan Decorations
    private let decorations: [Decoration]

    /// the StoreKit product to purchase
    private let product: (any ProductProtocol)?
    
    /// Current subscription data for Apple subscription checking
    private let currentSubscription: CurrentSubscriptionResponse?

    /// Initializer that takes an `AvailablePlan` (as returned from the API), one of its `PlanInstance`s,
    /// and the StoreKit product with matching identifier.
    /// The plan description is taken from the `AvailablePlan`. The duration and identifier com from the `PlanInstance`,
    /// and the localized price and the purchase action are derived from the `Product`

    // MARK: Current plan
    public init(currentPlan: CurrentSubscriptionResponse, isExpanded: Bool = false) {
        self.isExpanded = isExpanded
        self.currentSubscription = currentPlan
        
        let progressEntitlements = currentPlan.entitlements.compactMap {
            switch $0 {
            case let .progress(entitlement):
                entitlement
            default: nil
            }
        }

        self.descriptionEntitlements = currentPlan.entitlements.compactMap {
            switch $0 {
            case let .description(entitlement):
                entitlement
            default: nil
            }
        }

        self.description = currentPlan.description
        self.title = currentPlan.title
        self.name = currentPlan.name ?? String(localized: "current.free.plan.name")
        self.isFreePlan = currentPlan.name == nil
        self.progressEntitlements = progressEntitlements
        
        // Initial pricing setup - will be updated for Apple subscriptions
        self.formattedPrice = ProtonUIFoundations.Formatter.formatCurrency(amount: currentPlan.amount, currency: currentPlan.currency)
        self.formattedPeriod = currentPlan.cycleDescription ?? ""
        self.decorations = currentPlan.decorations
        self.product = nil
        
        // Check if this is an Apple subscription
        self.isAppleSubscription = AppleSubscriptionManager.shared.hasMatchingAppleSubscription(for: currentPlan)
        
        Logger.shared.log("Plan '\(currentPlan.title)': name=\(currentPlan.name ?? "nil"), external=\(currentPlan.external ?? -1), isAppleSubscription=\(isAppleSubscription)")
        
        if let endPeriod = currentPlan.periodEnd {
            let texts = [TextStyle(text: Constants.footerText(renew: currentPlan.renew ?? 0), font: .callout, color: Theme.color.shade80),
                         TextStyle(text: Formatter.formatDate(Double(endPeriod), formatType: .MMddYYYY), font: .headline, color: Theme.color.textNorm)]
            createFooterText(texts: texts)
        }
        
        // Set up Apple subscription monitoring if this is an Apple subscription
        if isAppleSubscription {
            setupAppleSubscriptionMonitoring()
            // Fetch actual StoreKit pricing for Apple subscriptions
            loadAppleSubscriptionPricing()
        }
    }

    // MARK: Public methods
    public func iconURLforEntitlement(_ entitlement: DescriptionEntitlement) -> URL? {
        URL(string: "https://lumo-api.proton.me/payments/v5/resources/icons/" + entitlement.iconName)
    }

    // MARK: Private methods
    private func createFooterText(texts: [TextStyle]) {
        renewFooter = TextStylizer.composeText(texts: texts)
    }

    // MARK: - Apple Subscription Pricing
    
    private func loadAppleSubscriptionPricing() {
        guard let subscription = currentSubscription,
              let productId = AppleSubscriptionManager.shared.getAppleProductId(for: subscription) else {
            Logger.shared.log("Cannot load Apple subscription pricing - missing subscription data or no matching Apple product ID found")
            return
        }
        
        Task {
            do {
                Logger.shared.log("Fetching StoreKit product for Apple subscription: \(productId)")
                let products = try await Product.products(for: [productId])
                
                if let storeKitProduct = products.first {
                    await MainActor.run {
                        // Update pricing to show actual StoreKit price the user paid
                        self.formattedPrice = storeKitProduct.displayPrice
                        Logger.shared.log("Updated Apple subscription pricing to StoreKit price: \(storeKitProduct.displayPrice) (was server price: \(ProtonUIFoundations.Formatter.formatCurrency(amount: subscription.amount, currency: subscription.currency)))")
                    }
                } else {
                    Logger.shared.log("No StoreKit product found for Apple subscription product ID: \(productId) - keeping server pricing")
                }
            } catch {
                Logger.shared.log("Error fetching StoreKit product for Apple subscription: \(error) - keeping server pricing")
                // Note: formattedPrice remains as server pricing (already set in init) if StoreKit fetch fails
            }
        }
    }

    // MARK: - Apple Subscription Management
    
    private func setupAppleSubscriptionMonitoring() {
        guard let subscription = currentSubscription,
              let productId = AppleSubscriptionManager.shared.getAppleProductId(for: subscription) else {
            Logger.shared.log("Cannot setup Apple subscription monitoring - missing subscription data or no matching Apple product ID found")
            return
        }
        
        Logger.shared.log("Setting up Apple subscription monitoring for product ID: \(productId)")
        
        // Initial status check
        updateAppleSubscriptionStatus(productId: productId)
        
        // Monitor for status changes
        Task {
            for await _ in AppleSubscriptionManager.shared.$subscriptionStatuses.values {
                await MainActor.run {
                    self.updateAppleSubscriptionStatus(productId: productId)
                }
            }
        }
    }
    
    private func updateAppleSubscriptionStatus(productId: String) {
        let manager = AppleSubscriptionManager.shared
        
        let wasCancelled = isAppleCancelled
        isAppleCancelled = manager.isSubscriptionCancelled(for: productId)
        appleCancellationDate = manager.getCancellationDate(for: productId)
        
        if wasCancelled != isAppleCancelled {
            Logger.shared.log("Apple subscription cancellation status changed for \(productId): cancelled=\(isAppleCancelled)")
        }
        
        if let status = manager.getSubscriptionStatus(for: productId) {
            let renewalStatus = switch status.renewalInfo {
            case .verified(let renewalInfo):
                "willAutoRenew=\(renewalInfo.willAutoRenew)"
            case .unverified:
                "willAutoRenew=unverified"
            }
            Logger.shared.log("Apple subscription status for \(productId): state=\(status.state), \(renewalStatus)")
        } else {
            Logger.shared.log("No Apple subscription status found for product ID: \(productId)")
        }
    }
    
    public func openAppleSubscriptionManagement() {
        Logger.shared.log("User tapped manage subscription button for Apple subscription")
        
        // Debug info for development
        AppleSubscriptionManager.shared.debugSubscriptionManagement()
        
        AppleSubscriptionManager.shared.openSubscriptionManagement()
    }
}

extension PlanViewModel: @preconcurrency Equatable {
    public static func == (lhs: PlanViewModel, rhs: PlanViewModel) -> Bool {
        return lhs.title == rhs.title &&
        lhs.description == rhs.description
    }
}

extension PlanViewModel: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

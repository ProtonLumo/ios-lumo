import Foundation
import StoreKit

public enum TransactionType {
    case successful
    case failed
    case renewal
    case alreadyProcessed
    case transactionUUIDNotFoundOrMismatching
    case unableToVerifyAccountsUUIDs
    case unknown
}

public protocol StoreKitObserverProviding: Sendable {
    func start() async throws
    func stop()
    func setPlans(_ plans: [String: Any])
    func addTransactionInProgress(_ transactionId: UInt64)
    func removeTransactionInProgress(_ transactionId: UInt64)
}

public enum StoreKitObserverError: Error {
    case missingListOfPlans
    case plansComposerFailedInit
    case requiredSubComponentInitFailed
    case impossibleToProcessTransaction
}

public final class StoreKitObserver: StoreKitObserverProviding, @unchecked Sendable {

    public static let shared = StoreKitObserver()
    @Published public private(set) var isON: Bool = false

    private var updates: Task<Void, Never>?
    private var transactionsInProgress = Set<UInt64>()
    private var transactionsCompleted = Set<UInt64>()
    private let queue = DispatchQueue(label: "storeKitObserver.syncQueue")
    private var plansComposer: PlansComposer?
    private var purchaseManager: PurchaseManager?
    private var plans: [String: Any] = [:]

    private init() {}

    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {

            for await unfinished in Transaction.unfinished {
                switch unfinished {
                case .verified(let transaction):

                    guard (await transaction.subscriptionStatus) != nil else {
                        Logger.shared.log("Transaction received is not a subscription", category: "Payment")
                        return
                    }

                    guard !transactionsInProgress.contains(transaction.id) else {
                        Logger.shared.log("Transaction already in progress, no action required", category: "Payment")
                        return
                    }

                    guard !transactionsCompleted.contains(transaction.id) else {
                        Logger.shared.log("Transaction completed by Proton, StoreKit transaction will be finished", category: "Payment")
                        await transaction.finish()
                        transactionsCompleted.remove(transaction.id)
                        return
                    }
                    await processTransaction(transaction)
                case .unverified(let transaction, let transactionError):
                    Logger.shared.log("Unverified unfinished transaction:\n \(transaction)\n \(transactionError)", category: "Payment")
                    return
                }
            }

            for await update in Transaction.updates {
                switch update {
                case .verified(let transaction):
                    guard let status = await transaction.subscriptionStatus else {
                        Logger.shared.log("Transaction received is not a subscription", category: "Payment")
                        return
                    }
                    switch status.state {
                    case .subscribed:
                        Logger.shared.log("Transaction already processed", category: "Payment")
                        return
                    default:
                        Logger.shared.log("Transaction state: \(status.state)", category: "Payment")
                    }
                case .unverified(let transaction, let transactionError):
                    Logger.shared.log("Unverified update transaction:\n \(transaction)\n \(transactionError)", category: "Payment")
                    return
                }
            }
        }
    }

    // MARK: Private functions
    private func initRequiredComponents() throws {
        guard !plans.isEmpty else {
            throw StoreKitObserverError.missingListOfPlans
        }

        plansComposer = PlansComposer(payload: plans)

        guard plansComposer != nil else {
            throw StoreKitObserverError.plansComposerFailedInit
        }
        purchaseManager = PurchaseManager()
    }

    private func processTransaction(_ transaction: Transaction) async {
        do {
            guard let plan = plansComposer?.matchPlanToStoreProduct(transaction.productID),
                    let appAccountToken = transaction.appAccountToken,
                    try verifyTransactionUUIDs(appAccountToken: appAccountToken, transactionUUID: UUID(uuidString: plansComposer?.uuidString ?? "") ?? UUID()),
                    let storeProduct = plansComposer?.storeProductWithId(transaction.productID) else {

                throw StoreKitObserverError.impossibleToProcessTransaction
            }

            try await purchaseManager?.purchase(storeProduct, plan: plan, uuid: appAccountToken)
        } catch {
            Logger.shared.log("StoreKitObserver error: Requirement to process the transaction haven't been met", category: "Payment")
        }
    }

    private func verifyTransactionUUIDs(appAccountToken: UUID, transactionUUID: UUID) throws -> Bool {
        return appAccountToken == transactionUUID
    }

    // MARK: Public methods
    public func start() throws {
        if !isON {
            try initRequiredComponents()
            guard plansComposer != nil else {
                Logger.shared.log("StoreKitObserver error: list of plans required to start the observer")
                throw StoreKitObserverError.requiredSubComponentInitFailed
            }

            updates?.cancel()
            updates = newTransactionListenerTask()
            isON = true
            Logger.shared.log("StoreKitObserver started: \(isON) ✅", category: "Payment")
        } else {
            Logger.shared.log("StoreKitObserver already running, nothing to start", category: "Payment")
        }
    }

    public func stop() {
        if isON {
            updates?.cancel()
            isON = false
            plansComposer = nil
            Logger.shared.log("StoreKitObserver stopped 🛑", category: "Payment")
        } else {
            Logger.shared.log("StoreKitObserver not started, nothing to stop 👍🏻", category: "Payment")
        }
    }

    public func setPlans(_ plans: [String: Any]) {
        queue.sync {
            self.plans = plans
        }
    }

    public func addTransactionInProgress(_ transactionId: UInt64) {
        queue.sync {
            _ = self.transactionsInProgress.insert(transactionId)
        }
    }

    public func removeTransactionInProgress(_ transactionId: UInt64) {
        queue.sync {
            _ = self.transactionsInProgress.remove(transactionId)
        }
    }
}

extension StoreKitObserver: PurchaseManagerDelegate {
    public func applePaymentCompleted() {
        Logger.shared.log("applePaymentCompleted")
    }
    
    public func tokenPostStarted() {
        Logger.shared.log("tokenPostStarted")
    }
    
    public func subscriptionPostStarted() {
        Logger.shared.log("Payment")
    }
    
    
    public func newSubscriptionPayload(payload: [String : Any]) {
        Logger.shared.log("newSubscriptionPayload")
    }
    
    public func paymentCompleted(success: Bool, message: String) {
        Logger.shared.log("Payment \(success ? "succeeded" : "failed"): \(message)", category: "Payment")
    }
}

import StoreKit
import WebKit

enum PurchaseManagerError: Error {
    case impossibleToGenerateUUID
    case transactionCancelledByUser
    case unknownError
    case transactionIdNotEqualToOriginalTransactionId
    case unableToGetBundleIdentifier
    case unableToGetTransactionAmountOrCurrency
    case unableToFindPlanName
    case tokenRequestFailed
    case tokenResponseInvalid
    case invalidTransactionID
}

public protocol PurchaseManagerDelegate: AnyObject {
    func newSubscriptionPayload(payload: [String: Any])
    func paymentCompleted(success: Bool, message: String)
    
    // Progress tracking methods
    func applePaymentCompleted()
    func tokenPostStarted()
    func subscriptionPostStarted()
}

class PurchaseManager: NSObject {
    
    // Make PurchaseManager a singleton
    static let shared = PurchaseManager()

    private var transaction: StoreKit.Transaction?
    private var tokenContinuation: CheckedContinuation<Void, Error>?
    private var refresh: SKReceiptRefreshRequest?
    public weak var delegate: PurchaseManagerDelegate?
    private weak var webView: WKWebView?
    
    // Store the composed plan for later use after token request
    private var pendingComposedPlan: ComposedPlan?
    private var pendingTransaction: ProtonTransactionProviding?

    public func setup(webView: WKWebView) {
        self.webView = webView
    }

    public func purchase(_ product: Product, plan: ComposedPlan, uuid: UUID?) async throws {
        Logger.shared.log("Starting purchase for \(product.id), plan: \(plan.plan.title)")

        guard let userTransactionUUID = uuid else {
            Logger.shared.log("Error: Missing UUID for transaction")
            throw PurchaseManagerError.impossibleToGenerateUUID
        }

        Logger.shared.log("Attempting to purchase product \(product.id)")
        let result = try await product.purchase(options: [.appAccountToken(userTransactionUUID)])

        switch result {
        case .success(let verificationResult):
            Logger.shared.log("Purchase successful, processing transaction")
            let transaction = try verificationResult.payloadValue
            self.transaction = transaction

            // ✅ Step 1: Apple Payment Completed
            Logger.shared.log("Notifying delegate: Apple payment completed")
            delegate?.applePaymentCompleted()

            Logger.shared.log("Starting receipt refresh request")
            try await withCheckedThrowingContinuation { continuation in
                tokenContinuation = continuation
                refresh = SKReceiptRefreshRequest()
                refresh?.delegate = self
                refresh?.start()
            }
            Logger.shared.log("Receipt refresh completed")
            
            Logger.shared.log("Transaction from Apple: \(transaction)")

            let protonTransaction = transaction.toProtonTransaction()
            guard protonTransaction.originalID == protonTransaction.id else {
                Logger.shared.log("Transaction error: originalId (\(transaction.originalID)) different from transactionId (\(transaction.id))")
                throw PurchaseManagerError.transactionIdNotEqualToOriginalTransactionId
            }
            // MARK: Generate payment token
            Logger.shared.log("Generating validation token")
            try generateValidationTokenFromStoreKitReceipt(protonTransaction, composedPlan: plan)
            Logger.shared.log("Transaction processing complete, adding to in-progress transactions")
            StoreKitObserver.shared.addTransactionInProgress(transaction.id)
            
        case .pending:
            Logger.shared.log("Transaction is pending")
        case .userCancelled:
            Logger.shared.log("Transaction cancelled by the user")
            throw PurchaseManagerError.transactionCancelledByUser
        @unknown default:
            Logger.shared.log("Unknown transaction error")
            throw PurchaseManagerError.unknownError
        }
    }
}

private extension PurchaseManager {

    private func generateValidationTokenFromStoreKitReceipt(_ transaction: ProtonTransactionProviding, composedPlan: ComposedPlan) throws {
        Logger.shared.log("Generating validation token from StoreKit receipt")

        do {
        let receipt = try StoreKitReceiptManager.fetchPurchaseReceipt()
            Logger.shared.log("Successfully fetched purchase receipt")

        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
                Logger.shared.log("Error: Bundle identifier not found")
            throw PurchaseManagerError.unableToGetBundleIdentifier
        }

            Logger.shared.log("Transaction info: \(transaction)");

        guard let amount = transaction.price, let currency = transaction.currencyIdentifier else {
                Logger.shared.log("Error: Could not get amount and currency from transaction")
            throw PurchaseManagerError.unableToGetTransactionAmountOrCurrency
        }

        let formattedAmount = NSDecimalNumber(decimal: amount * 100).intValue
            Logger.shared.log("Payment amount: \(formattedAmount) \(currency)")
            
        let newToken = Token(amount: formattedAmount,
                             currency: currency,
                             payment: PaymentReceipt(details: ReceiptDetails(bundleID: bundleIdentifier,
                                                                             productID: transaction.productID,
                                                                             receipt: receipt,
                                                                                 transactionID: String(transaction.originalID)),
                                                     type: "apple-recurring"),
                             paymentMethodID: nil)

            Logger.shared.log("Payment token generated successfully")
            
            // Store the plan and transaction for use after token request
            self.pendingComposedPlan = composedPlan
            self.pendingTransaction = transaction
            
            // Send token to WebView
            guard let webView = self.webView else {
                Logger.shared.log("Error: WebView not available for token request")
                delegate?.paymentCompleted(success: false, message: "WebView not available for payment")
                return
            }
            
            var tokenPayload = newToken.toDictionary()
            
            // ✅ Step 2: Token Post Started
            Logger.shared.log("Notifying delegate: Token post started")
            delegate?.tokenPostStarted()
            
            PaymentBridge.shared.sendPaymentTokenToWebView(webView: webView, payload: tokenPayload) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    Logger.shared.log("Token request successful")
                    
                    guard let data = response.data, let tokenValue = data["Token"] as? String else {
                        Logger.shared.log("Error: Token not found in response data")
                        self.delegate?.paymentCompleted(success: false, message: "Invalid token response")
                        return
                    }
                    
                    Logger.shared.log("Token received: \(tokenValue)")
                    
                    do {
                        // Create subscription with the token
                        guard let composedPlan = self.pendingComposedPlan, let transaction = self.pendingTransaction else {
                            Logger.shared.log("Error: Missing pending plan or transaction")
                            self.delegate?.paymentCompleted(success: false, message: "Internal payment error")
                            return
                        }
                        
                        let newSub = try self.createNewSubscription(composedPlan: composedPlan, 
                                                               transaction: transaction, 
                                                               token: tokenValue)

                        // Send subscription request
                        self.sendSubscriptionRequest(subscription: newSub)
                    } catch {
                        Logger.shared.log("Error creating subscription: \(error)")
                        self.delegate?.paymentCompleted(success: false, message: "Failed to create subscription")
                    }
                    
                case .failure(let error):
                    Logger.shared.log("Token request failed: \(error)")
                    self.delegate?.paymentCompleted(success: false, message: "Token request failed: \(error.localizedDescription)")
                }
            }
        } catch {
            Logger.shared.log("Error generating validation token: \(error)")
            delegate?.paymentCompleted(success: false, message: "Failed to generate payment token")
            throw error
        }
    }
    
    private func sendSubscriptionRequest(subscription: CreateSubscription) {
        Logger.shared.log("Sending subscription request")
        
        guard let webView = self.webView else {
            Logger.shared.log("Error: WebView not available for subscription request")
            delegate?.paymentCompleted(success: false, message: "WebView not available for payment")
            return
        }
        
        let subscriptionPayload = subscription.toDictionary()
        
        // ✅ Step 3: Subscription Post Started
        Logger.shared.log("Notifying delegate: Subscription post started")
        delegate?.subscriptionPostStarted()
        
        PaymentBridge.shared.sendSubscriptionToWebView(webView: webView, payload: subscriptionPayload) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                Logger.shared.log("Subscription request successful: \(response.data ?? [:])")
                self.delegate?.newSubscriptionPayload(payload: subscriptionPayload)
                // ✅ Step 4: All completed - handled in paymentCompleted with success: true
                self.delegate?.paymentCompleted(success: true, message: "Payment successful! You now have Lumo Plus.")
                
            case .failure(let error):
                Logger.shared.log("Subscription request failed: \(error)")
                self.delegate?.paymentCompleted(success: false, message: "Subscription failed: \(error.localizedDescription)")
            }
        }
    }

    private func createNewSubscription(composedPlan: ComposedPlan, 
                                       transaction: ProtonTransactionProviding,
                                       token: String) throws -> CreateSubscription {
        Logger.shared.log("Creating new subscription for plan: \(composedPlan.plan.title)")

        guard let planName = composedPlan.plan.name else {
            Logger.shared.log("Error: Unable to find plan name")
            throw PurchaseManagerError.unableToFindPlanName
        }

        Logger.shared.log("Plan name: \(planName), cycle: \(composedPlan.instance.cycle), currency: \(transaction.currencyIdentifier ?? "Unknown")")

        let newSub = CreateSubscription(paymentToken: token,
                                        cycle: composedPlan.instance.cycle,
                                        currency: transaction.currencyIdentifier,
                                        plans: [planName: 1])
        Logger.shared.log("New subscription payload created successfully")

        return newSub
    }
}

extension PurchaseManager: SKRequestDelegate {

    public func requestDidFinish(_ request: SKRequest) {
        cancelActiveRequest(request)
        Logger.shared.log("Apple transaction completed", category: "Payment")
        tokenContinuation?.resume()
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        cancelActiveRequest(request)
        Logger.shared.log("Apple transaction failed", category: "Payment")
        tokenContinuation?.resume(throwing: error)
        debugPrint(error)
    }

    private func cancelActiveRequest(_ request: SKRequest) {
        request.cancel()
        refresh = nil
    }
}


import Foundation
import ProtonUIFoundations
import StoreKit
import SwiftUI

// MARK: - Import TransactionProgressView
// Note: Import is not needed as TransactionProgressView is in the same target

enum PaymentSheetError: LocalizedError {
    case errorCovertingPayload
    case lumoPlanNotFound
    case multiplePlansSelected
    case impossibleToExtractUUID
}

enum PlanType: String {
    case year
    case month
}

public protocol PaymentSheetViewModelDelegate: AnyObject {
    func subscriptionRequest(payload: [String: Any])
    func tokenRequest(payload: [String: Any])
    func getPlansRequest()
    func getSubscriptionsRequest()
}

@MainActor
class PaymentSheetViewModel: ObservableObject {

    private let planComposer: PlansComposer
    private let purchaseManager: PurchaseManager
    private var plans: [ComposedPlan] = []
    private var lumoPlans: [ComposedPlan]!

    @Published var descriptionEntitlements: [FeatureRowModel] = []
    @Published var planOptions: [PlanOptionViewModel] = []
    @Published var planTitle: String = ""
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var isSuccess: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isLoadingPlans: Bool = true
    @Published var selectedPlanType: PlanType = .year
    
    // Transaction Progress Integration
    @Published var showTransactionProgress: Bool = false
    @Published var transactionProgressViewModel = TransactionProgressViewModel()
    
    // Promotion offer flag
    let isPromotionOffer: Bool
    
    // Computed property to check if no plans are available
    var hasNoPlansAvailable: Bool {
        !isLoadingPlans && planOptions.isEmpty
    }
    
    // Computed property to check if yearly plan is selected
    var isYearlyPlanSelected: Bool {
        selectedPlanType == .year
    }

    public weak var delegate: PaymentSheetViewModelDelegate?

    init(planComposer: PlansComposer, isPromotionOffer: Bool = false) {
        self.isPromotionOffer = true
        self.planComposer = planComposer

        purchaseManager = PurchaseManager.shared
        purchaseManager.delegate = self
        
        // Setup transaction progress callbacks
        setupTransactionProgressCallbacks()
        
        Task {
            await fetchPlans()
        }
    }

    private func fetchPlans() async {
        isLoadingPlans = true
        
        do {
            self.plans = try await self.planComposer.fetchAvailablePlans()
            self.lumoPlans = plans.filter { $0.plan.title == "Lumo Plus" }
            extractPlanOptions()
            extractEntitlements()
        } catch {
            Logger.shared.log("Error fetching plans: \(error)")
            // Fallback to empty plans on error
            self.plans = []
            self.lumoPlans = []
        }
        
        isLoadingPlans = false
    }

    // MARK: Public
    public func planOptionSelected(_ id: String) {
        _ = planOptions.map {
            _ = $0.id == id ? $0.setSelected(true) : $0.setSelected(false)
        }
        
        // Update the selected plan type to trigger UI updates
        if let selectedPlan = planOptions.first(where: { $0.id == id }) {
            selectedPlanType = selectedPlan.type
        }
    }

    public func purchaseProduct() async throws {
        isLoading = true
        showTransactionProgressView()

        Logger.shared.log("Starting purchase product process")
        let optionToPurchase = planOptions.filter { $0.isSelected == true }
        guard optionToPurchase.count == 1, let plan = optionToPurchase.first, let product = plan.plan.product as? Product else {
            Logger.shared.log("Error: No plan selected or multiple plans selected")
            isLoading = false
            hideTransactionProgress()
            showAlert(success: false, title: "Error", message: "Please select a plan")
            throw PaymentSheetError.multiplePlansSelected
        }

        Logger.shared.log("Plan selected: \(plan.title), checking UUID")
        
        // Validate UUID
        if planComposer.uuidString.isEmpty {
            Logger.shared.log("Error: UUID string is empty")
            isLoading = false
            hideTransactionProgress()
            showAlert(success: false, title: "Error", message: "Invalid transaction identifier")
            throw PaymentSheetError.impossibleToExtractUUID
        }

        guard let uuid = UUID(uuidString: planComposer.uuidString) else {
            Logger.shared.log("Error: Invalid UUID format: \(planComposer.uuidString)")
            isLoading = false
            hideTransactionProgress()
            showAlert(success: false, title: "Error", message: "Invalid transaction identifier format")
            throw PaymentSheetError.impossibleToExtractUUID
        }

        Logger.shared.log("Valid UUID found, proceeding with purchase")
        do {
        try await purchaseManager.purchase(product, plan: plan.plan, uuid: uuid)
        } catch {
            isLoading = false
            transactionProgressViewModel.markError(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Transaction Progress Methods
    
    private func showTransactionProgressView() {
        showTransactionProgress = true
    }
    
    func hideTransactionProgress() {
        showTransactionProgress = false
    }
    
    // MARK: - Progress Event Methods (called by PurchaseManager)
    
    func markApplePaymentCompleted() {
        Logger.shared.log("PaymentSheetViewModel: markApplePaymentCompleted called")
        transactionProgressViewModel.markApplePaymentCompleted()
    }
    
    func markTokenPostStarted() {
        Logger.shared.log("PaymentSheetViewModel: markTokenPostStarted called")
        transactionProgressViewModel.markTokenPostStarted()
    }
    
    func markSubscriptionPostStarted() {
        Logger.shared.log("PaymentSheetViewModel: markSubscriptionPostStarted called")
        transactionProgressViewModel.markSubscriptionPostStarted()
    }
    
    func markAllCompleted() {
        Logger.shared.log("PaymentSheetViewModel: markAllCompleted called")
        transactionProgressViewModel.markAllCompleted()
    }
    
    func markPaymentError(_ message: String) {
        Logger.shared.log("PaymentSheetViewModel: markPaymentError called with message: \(message)")
        transactionProgressViewModel.markError(message)
    }
    
    private func showAlert(success: Bool, title: String, message: String) {
        self.isSuccess = success
        self.alertTitle = title
        self.alertMessage = message
        self.showAlert = true
        
        if success {
            // Don't auto-dismiss anymore - let TransactionProgressView handle completion
            // DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            //     self.shouldDismiss = true
            // }
        }
    }

    // MARK: Private
    private func extractEntitlements() {
        guard let plan = lumoPlans.first else {
            Logger.shared.log("Lumo plan not found")
            return
        }

        let entitlements = plan.plan.entitlements.compactMap {
            switch $0 {
            case let .description(entitlement):
                FeatureRowModel(icon: entitlement.iconName,
                                text: entitlement.text)
            default: nil
            }
        }
        DispatchQueue.main.async {
            self.planTitle = plan.plan.title
            self.descriptionEntitlements = entitlements
        }
    }

    private func calculateSavingValue() -> Double {
        guard let monthlyPlan = lumoPlans.filter({ $0.instance.cycle == 1}).first, let yearlyPlan = lumoPlans.filter({ $0.instance.cycle == 12}).first else {
            Logger.shared.log("Unable to calculate plans saving value")
            return 0
        }

        let monthPlanYearly = monthlyPlan.product.price * 12
        let saving = monthPlanYearly - yearlyPlan.product.price
        return NSDecimalNumber(decimal: saving * 100).doubleValue
    }

    private func extractPlanOptions() {
        DispatchQueue.main.async {
            self.lumoPlans.forEach { plan in
                self.planOptions.append(PlanOptionViewModel(plan: plan, discount: self.calculateSavingValue()))
            }
        }
    }

    // MARK: - Transaction Progress Setup
    
    private func setupTransactionProgressCallbacks() {
        transactionProgressViewModel.onCompletion = { [weak self] in
            Task { @MainActor in
                self?.hideTransactionProgress()
                self?.shouldDismiss = true
            }
        }
        
        transactionProgressViewModel.onError = { [weak self] errorMessage in
            print("PaymentSheetViewModel: onError callback triggered with message: \(errorMessage)")
            Task { @MainActor in
                print("PaymentSheetViewModel: Hiding transaction progress and resetting loading state")
                self?.hideTransactionProgress()
                // Reset loading state when returning to payment screen
                self?.isLoading = false
            }
        }
    }
}

extension PaymentSheetViewModel: PurchaseManagerDelegate {
    
    func newSubscriptionPayload(payload: [String : Any]) {
        Logger.shared.log("PaymentSheetViewModel received subscription payload, forwarding to delegate")
        if delegate == nil {
            Logger.shared.log("WARNING: PaymentSheetViewModel delegate is nil, subscription payload will not be forwarded")
        }
        delegate?.subscriptionRequest(payload: payload)
    }
    
    func paymentCompleted(success: Bool, message: String) {
        Task { @MainActor in
            self.isLoading = false
            
            if success {
                // Mark all completed in progress view
                self.markAllCompleted()
            } else {
                // Show error in progress view
                self.markPaymentError(message)
            }
        }
    }
    
    // MARK: - Progress tracking delegate methods
    func applePaymentCompleted() {
        Logger.shared.log("Progress: Apple payment completed")
        Task { @MainActor in
            self.markApplePaymentCompleted()
        }
    }
    
    func tokenPostStarted() {
        Logger.shared.log("Progress: Token post started")
        Task { @MainActor in
            self.markTokenPostStarted()
        }
    }
    
    func subscriptionPostStarted() {
        Logger.shared.log("Progress: Subscription post started")
        Task { @MainActor in
            self.markSubscriptionPostStarted()
        }
    }
}

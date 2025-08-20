import Foundation
import SwiftUI

@MainActor
class TransactionProgressViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var stepStates: [Bool] = [false, false, false, false]
    @Published var isCompleted = false
    @Published var hasError = false
    @Published var errorMessage = ""
    
    let progressSteps = [
        String(localized: "app.payment.transaction.step.confirming"), // "Confirming your payment",
        String(localized: "app.payment.transaction.step.updating"), //"Updating your account",
        String(localized: "app.payment.transaction.step.updated") // "Account updated",
    ]
    
    var onCompletion: (() -> Void)?
    var onError: ((String) -> Void)?
    
    init() {}
    
    // MARK: - Public Event Methods
    
    func startPaymentProcess() {
        resetToInitialState()
    }
    
    func markApplePaymentCompleted() {
        Logger.shared.log("TransactionProgressViewModel: markApplePaymentCompleted - completing step 0")
        completeStep(0)
    }
    
    func markTokenPostStarted() {
        Logger.shared.log("TransactionProgressViewModel: markTokenPostStarted - completing step 1")
        completeStep(1)
    }
    
    func markSubscriptionPostStarted() {
        Logger.shared.log("TransactionProgressViewModel: markSubscriptionPostStarted - completing step 2")
        completeStep(2)
    }
    
    func markAllCompleted() {
        Logger.shared.log("TransactionProgressViewModel: markAllCompleted - completing step 3")
        withAnimation(.easeInOut(duration: 0.3)) {
            isCompleted = true
        }
        
    }
    
    func markError(_ message: String) {
        Logger.shared.log("TransactionProgressViewModel: markError - \(message)")
        withAnimation(.easeInOut(duration: 0.3)) {
            hasError = true
            errorMessage = message
        }
        onError?(message)
    }
    
    func resetToPaymentScreen() {
        resetToInitialState()
    }
    
    // MARK: - Private Methods
    
    private func resetToInitialState() {
        stepStates = [false, false, false, false]
        currentStep = 0
        isCompleted = false
        hasError = false
        errorMessage = ""
    }
    
    private func completeStep(_ step: Int) {
        guard step < stepStates.count else {
            return 
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            stepStates[step] = true
            if step < progressSteps.count - 1 {
                currentStep = step + 1
            }
        }
    }
}

// MARK: - Convenience Methods
extension TransactionProgressViewModel {
    func setCompletionHandler(_ handler: @escaping () -> Void) {
        onCompletion = handler
    }
    
    func setErrorHandler(_ handler: @escaping (String) -> Void) {
        onError = handler
    }
} 

import SwiftUI
import ProtonUIFoundations
import UIKit
import Lottie

struct TransactionProgressView: View {
    @ObservedObject var viewModel: TransactionProgressViewModel
    
    // Callbacks for external control
    var onCompletion: (() -> Void)?
    var onError: (() -> Void)?
    var onBackToPayment: (() -> Void)?
    
    init(viewModel: TransactionProgressViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if viewModel.hasError {
                errorView
            } else {
                progressView
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        .onAppear {
            setupCallbacks()
            viewModel.startPaymentProcess()
        }
    }
    
    private var progressView: some View {
        VStack(spacing: 32) {
            LottieView(name: "lumo-hero")
                .frame(width: 200, height: 150)
            
            VStack(spacing: 16) {
                Text(String(localized: "app.payment.verifying.title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text(String(localized: "app.payment.verifying.subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Progress steps
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(viewModel.progressSteps.enumerated()), id: \.offset) { index, stepTitle in
                    HStack(spacing: 12) {
                        // Step indicator
                        ZStack {
                            Circle()
                                .fill(viewModel.stepStates[index] ? Theme.color.iconAccent : Color.gray.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            if viewModel.stepStates[index] {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                            } else if index == viewModel.currentStep && !viewModel.isCompleted {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(.gray)
                            }
                        }
                        
                        Text(stepTitle)
                            .font(.body)
                            .foregroundColor(viewModel.stepStates[index] ? .black : .gray)
                            .transition(.opacity)
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.stepStates[index])
                }
            }
            .padding(.horizontal, 15)
            
            // Completion button - shown when all steps are completed
            if viewModel.isCompleted {
                Button(action: {
                    onCompletion?()
                }) {
                    Text(String(localized: "app.payment.verifying.experience"))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.color.iconAccent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.5).delay(0.3), value: viewModel.isCompleted)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 60)
    }
    
    private var errorView: some View {
        VStack(spacing: 32) {
            // Error icon or animation
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            VStack(spacing: 16) {
                Text(String(localized: "app.payment.verifying.error.title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text(viewModel.errorMessage.isEmpty ? String(localized: "app.payment.verifying.error.info") : viewModel.errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                print("TransactionProgressView: Back to Payment button pressed")
                // Trigger the back to payment callback to return to payment screen
                onBackToPayment?()
                print("TransactionProgressView: Called onBackToPayment callback")
            }) {
                Text(String(localized: "app.payment.verifying.backtopayment"))
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.color.iconAccent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 60)
    }
    
    private func setupCallbacks() {
        viewModel.setCompletionHandler {
            onCompletion?()
        }
        
        viewModel.setErrorHandler { errorMessage in
            // Error UI is handled by @Published hasError
            // But we also want to trigger the onError callback when the button is pressed
            onError?()
        }
    }
}

// MARK: - Convenience Methods for External Control
extension TransactionProgressView {
    func onCompletion(_ handler: @escaping () -> Void) -> TransactionProgressView {
        var view = self
        view.onCompletion = handler
        return view
    }
    
    func onError(_ handler: @escaping () -> Void) -> TransactionProgressView {
        var view = self
        view.onError = handler
        return view
    }
    
    func onBackToPayment(_ handler: @escaping () -> Void) -> TransactionProgressView {
        var view = self
        view.onBackToPayment = handler
        return view
    }
}

#Preview {
    TransactionProgressView(viewModel: TransactionProgressViewModel())
} 

import Foundation
import WebKit
import SwiftUI

public enum PaymentHandlerActionType {
    case createSubscription
    case createToken
    case getPlans
    case getSubscriptions
}

public struct PaymentHandlerActions {
    let type: PaymentHandlerActionType
    let payload: [String: Any]
}

class PaymentHandler: NSObject, WKScriptMessageHandler {

    private var completion: (PaymentHandlerActions) -> Void
    private weak var webView: WKWebView?

    public init(webView: WKWebView, completion: @escaping (PaymentHandlerActions) -> Void) {
        self.webView = webView
        self.completion = completion
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "showPayment" {
            // Safely cast the message body to a Dictionary
            guard message.body is [String: Any] else {
                Logger.shared.log("PaymentHandler received unexpected message body: \(message.body)")
                return
            }
            
            // Trigger the payment flow
            fetchAndShowPaymentSheet()
        }
    }
    
    /// Public method to fetch plans and show payment sheet
    /// Can be called from JavaScript message handler or from native code
    public func fetchAndShowPaymentSheet() {
        // Make sure we have a webView
        guard let webView = self.webView else {
            Logger.shared.log("WebView not available for payment handler")
            return
        }
        
        Logger.shared.log("Fetching plans from WebView...")
        
        // Fetch plans from WebView using the shared instance
        PaymentBridge.shared.getPlansFromWebView(webView: webView) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    guard let planData = response.data else {
                        Logger.shared.log("No plan data received from WebView")
                        return
                    }
                    
                    Logger.shared.log("Plans received from WebView, showing payment sheet")
                    self.showPaymentSheet(with: planData)
                    
                case .failure(let error):
                    Logger.shared.log("Failed to fetch plans from WebView: \(error)")
                    
                    // Check if this is an authentication error
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("UID must be set") {
                        // User is not signed in - show authentication required alert
                        self.showAuthenticationRequiredAlert()
                    } else {
                        // Other errors - fallback to using plans.json
                        Logger.shared.log("Falling back to plans.json")
                        do {
                            let mockResponse = try Bundle.main.loadJsonDataToDic(from: "plans.json")
                            self.showPaymentSheet(with: mockResponse)
                        } catch {
                            Logger.shared.log("Failed to load fallback plans.json: \(error.localizedDescription)")
                            self.showGenericErrorAlert()
                        }
                    }
                }
            }
        }
    }
    
    private func showPaymentSheet(with planData: [String: Any]) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // Initialize PaymentSheet with the plans data
            let composer = PlansComposer(payload: planData)
            let viewModel = PaymentSheetViewModel(planComposer: composer)
            viewModel.delegate = self
            let paymentSheet = PaymentSheet(viewModel: viewModel)
            let hostingController = UIHostingController(rootView: paymentSheet)
            hostingController.modalPresentationStyle = .formSheet
            windowScene.windows.first?.rootViewController?.present(hostingController, animated: true)
        }
    }
    
    private func showAuthenticationRequiredAlert() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let alert = UIAlertController(
                    title: String(localized: "app.payment.authRequired.title"),
                    message: String(localized: "app.payment.authRequired.message"),
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: String(localized: "app.general.ok"), style: .default))
                
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    private func showGenericErrorAlert() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let alert = UIAlertController(
                    title: String(localized: "app.general.error"),
                    message: String(localized: "app.payment.error.generic"),
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: String(localized: "app.general.ok"), style: .default))
                
                rootViewController.present(alert, animated: true)
            }
        }
    }
}

extension PaymentHandler: PaymentSheetViewModelDelegate {

    func subscriptionRequest(payload: [String: Any]) {
        let action = PaymentHandlerActions(type: .createSubscription, payload: payload)
        completion(action)
    }
    
    func tokenRequest(payload: [String: Any]) {
        let action = PaymentHandlerActions(type: .createToken, payload: payload)
        completion(action)
    }
    
    func getPlansRequest() {
        // Use an empty payload for requests that don't need data
        let action = PaymentHandlerActions(type: .getPlans, payload: [:])
        completion(action)
    }
    
    func getSubscriptionsRequest() {
        // Use an empty payload for requests that don't need data
        let action = PaymentHandlerActions(type: .getSubscriptions, payload: [:])
        completion(action)
    }
}

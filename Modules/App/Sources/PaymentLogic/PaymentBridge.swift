import Foundation
import WebKit
import os.log

 
enum PaymentRequestType {
    case paymentToken
    case subscription
    case getPlans
    case getSubscriptions
    
    var functionName: String {
        switch self {
        case .paymentToken:
            return "postPaymentToken"
        case .subscription:
            return "postSubscription"
        case .getPlans:
            return "getPlans"
        case .getSubscriptions:
            return "getSubscriptions"
        }
    }
}


/// Response structure for JavaScript payment operations
struct PaymentJsResponse {
    let status: String
    let data: [String: Any]?
    let message: String?
    
    init(status: String, data: [String: Any]? = nil, message: String? = nil) {
        self.status = status
        self.data = data
        self.message = message
    }
}


/// Class to handle payment-related interactions with the WebView
class PaymentBridge {
    static let shared = PaymentBridge()
    
    private static let TAG = "PaymentBridge"
    private var pendingJsCallbacks: [String: (Result<PaymentJsResponse, Error>) -> Void] = [:]
    private let callbacksLock = NSLock() // Lock for thread safety
    private let callbackQueue = DispatchQueue(label: "com.lumo.PaymentBridge.callbacks", qos: .userInitiated)
    
    /**
     * Generic method to send data to the WebView's JavaScript API
     *
     * @param webView The WebView instance to communicate with
     * @param payload The data payload to send (optional, will be converted to JSON if provided)
     * @param jsFunction The JavaScript function to invoke
     * @param callback Optional callback to receive the result
     */
    func sendDataToWebView(
        webView: WKWebView,
        payload: [String: Any]?,
        jsFunction: PaymentRequestType,
        callback: ((Result<PaymentJsResponse, Error>) -> Void)? = nil
    ) {
        // Ensure we're on the main thread for all WebView operations
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.sendDataToWebView(webView: webView, payload: payload, jsFunction: jsFunction, callback: callback)
            }
            return
        }
        
        let payloadJson: String
        
        if let payload = payload {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
                payloadJson = String(data: jsonData, encoding: .utf8) ?? "null"
            } catch {
                Logger.shared.log("Error encoding payload: \(error)")
                callback?(.failure(error))
                return
            }
        } else {
            payloadJson = "null"
        }
        
        // Generate a unique ID for this transaction
        let transactionId = UUID().uuidString
        
        // Store the callback if it exists
        if let callback = callback {
            callbacksLock.lock()
            pendingJsCallbacks[transactionId] = callback
            callbacksLock.unlock()
        }
        
        Logger.shared.log("Sending \(jsFunction.functionName) (ID: \(transactionId))...")
        Logger.shared.log("Payload: \(payloadJson)")
        
        // Construct the JavaScript call
        let jsFunctionCall: String
        if jsFunction == .getPlans || jsFunction == .getSubscriptions {
            jsFunctionCall = "window.paymentApiInstance.\(jsFunction.functionName)('ios')"
        } else {
            jsFunctionCall = "window.paymentApiInstance.\(jsFunction.functionName)(\(payloadJson))"
        }
        
        // JavaScript that will call back to the iOS app
        let js = """
        (async function() {
            const txId = '\(transactionId)';
            try {
                if (window.paymentApiInstance && typeof window.paymentApiInstance.\(jsFunction.functionName) === 'function') {
                    const result = await \(jsFunctionCall);
                    const resultJson = JSON.stringify({ status: 'success', data: result });
                    window.webkit.messageHandlers.paymentBridgeCallback.postMessage({ txId: txId, result: resultJson });
                } else {
                    const errorMsg = 'paymentApiInstance or \(jsFunction.functionName) not found';
                    console.error(errorMsg);
                    const errorJson = JSON.stringify({ status: 'error', message: errorMsg });
                    window.webkit.messageHandlers.paymentBridgeCallback.postMessage({ txId: txId, result: errorJson });
                }
            } catch (e) {
                const errorMessage = e instanceof Error ? e.message : String(e);
                console.error('Error executing \(jsFunction.functionName):', errorMessage);
                const errorJson = JSON.stringify({ status: 'error', message: 'JS Error: ' + errorMessage });
                window.webkit.messageHandlers.paymentBridgeCallback.postMessage({ txId: txId, result: errorJson });
            }
        })();
        """
        
        // Ensure evaluateJavaScript is called on the main thread
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    /**
     * Process a JavaScript result message from WebView
     */
    func processJavascriptResult(_ result: String, transactionId: String) {
        callbacksLock.lock()
        guard let callback = pendingJsCallbacks[transactionId] else {
            callbacksLock.unlock()
            Logger.shared.log("No callback found for transaction ID: \(transactionId)")
            return
        }
        
        // Remove the callback immediately to prevent duplicate processing
        pendingJsCallbacks.removeValue(forKey: transactionId)
        callbacksLock.unlock()
        
        DispatchQueue.main.async {
        do {
            guard let data = result.data(using: .utf8) else {
                callback(.failure(NSError(domain: "PaymentBridge", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])))
                return
            }
            
            guard let parsedResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                callback(.failure(NSError(domain: "PaymentBridge", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                return
            }
            
            let status = parsedResponse["status"] as? String ?? "error"
            let responseData = parsedResponse["data"] as? [String: Any]
            let message = parsedResponse["message"] as? String
            
            let response = PaymentJsResponse(
                status: status,
                data: responseData,
                message: message
            )
            
            if status == "success" {
                callback(.success(response))
            } else {
                callback(.failure(NSError(domain: "PaymentBridge", code: 1003, userInfo: [NSLocalizedDescriptionKey: message ?? "Unknown error from JS"])))
            }
        } catch {
            Logger.shared.log("Error processing JS response: \(error)")
            callback(.failure(error))
            }
        }
    }
    
    // MARK: - Convenience methods

    /**
     * Send payment token to WebView
     */
    func sendPaymentTokenToWebView(
        webView: WKWebView,
        payload: [String: Any],
        callback: ((Result<PaymentJsResponse, Error>) -> Void)? = nil
    ) {
        // Ensure we always dispatch from the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.sendPaymentTokenToWebView(webView: webView, payload: payload, callback: callback)
            }
            return
        }
        
        sendDataToWebView(webView: webView, payload: payload, jsFunction: .paymentToken, callback: callback)
    }
    
    /**
     * Send subscription data to WebView
     */
    func sendSubscriptionToWebView(
        webView: WKWebView,
        payload: [String: Any],
        callback: ((Result<PaymentJsResponse, Error>) -> Void)? = nil
    ) {
        // Ensure we always dispatch from the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.sendSubscriptionToWebView(webView: webView, payload: payload, callback: callback)
            }
            return
        }
        
        sendDataToWebView(webView: webView, payload: payload, jsFunction: .subscription, callback: callback)
    }
    
    /**
     * Get plans from WebView
     */
    func getPlansFromWebView(
        webView: WKWebView,
        callback: ((Result<PaymentJsResponse, Error>) -> Void)? = nil
    ) {
        // Ensure we always dispatch from the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.getPlansFromWebView(webView: webView, callback: callback)
            }
            return
        }
        
        sendDataToWebView(webView: webView, payload: nil, jsFunction: .getPlans, callback: callback)
    }
    
    /**
     * Get subscriptions from WebView
     */
    func getSubscriptionsFromWebView(
        webView: WKWebView,
        callback: ((Result<PaymentJsResponse, Error>) -> Void)? = nil
    ) {
        // Ensure we always dispatch from the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.getSubscriptionsFromWebView(webView: webView, callback: callback)
            }
            return
        }
        
        sendDataToWebView(webView: webView, payload: nil, jsFunction: .getSubscriptions, callback: callback)
    }
} 

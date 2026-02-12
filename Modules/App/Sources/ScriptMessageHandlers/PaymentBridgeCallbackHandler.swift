import LumoCore
import WebKit

final class PaymentBridgeCallbackHandler: NSObject, WKScriptMessageHandler, WKMessageHandlerRegistering {
    // MARK: - WKMessageHandlerRegistering

    enum MessageName: String, CaseIterable {
        case paymentBridgeCallback
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = MessageName(rawValue: message.name)

        switch messageName {
        case .paymentBridgeCallback:
            guard
                let messageBody = message.body as? [String: Any],
                let txId = messageBody["txId"] as? String,
                let resultString = messageBody["result"] as? String
            else {
                Logger.shared.log("Error: Invalid payment bridge callback message format")
                return
            }

            Logger.shared.log("Payment bridge callback received for transaction: \(txId)")
            PaymentBridge.shared.processJavascriptResult(resultString, transactionId: txId)
        case .none:
            break
        }
    }
}

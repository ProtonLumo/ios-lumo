import WebKit

final class UnifiedMessageHandler: NSObject, WKScriptMessageHandler {
    let parent: WebView
    private var lastSubmitTime: Date?
    private let submitDebounceInterval: TimeInterval = 0.5

    init(_ parent: WebView) {
        self.parent = parent
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = message.name
        Logger.shared.log("📨 Received message: \(messageName)")

        DispatchQueue.main.async {
            switch messageName {
            case "navigationState":
                self.handleNavigationState(message)
            case "paymentResponse":
                self.handlePaymentResponse(message)
            case "submitButtonClicked":
                self.handleSubmitButtonClicked()
            case "elementFound":
                self.handleElementFound(message)
            case "insertPrompt":
                self.handleInsertPrompt(message)
            case "startVoiceEntry":
                self.handleStartVoiceEntry()
            case "promotionButtonClicked":
                self.handlePromotionButtonClicked(message)
            case "managePlanClicked":
                self.handleManagePlanClicked()
            case "getSubscriptionsResponseReceived":
                self.handleGetSubscriptionsResponse(message)
            case "openExternalURL":
                self.handleOpenExternalURL(message)
            default:
                Logger.shared.log("⚠️ Unknown message: \(messageName)")
            }
        }
    }

    private func handleNavigationState(_ message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else { return }

        if let action = dict["action"] as? String, action == "forceBack" {
            Logger.shared.log("Received forceBack action from JavaScript")
            if let webView = self.parent.webViewStore, webView.canGoBack {
                webView.goBack()
            }
            return
        }

        if let canGoBack = dict["canGoBack"] as? Bool {
            let nativeCanGoBack = self.parent.webViewStore?.canGoBack ?? false
            self.parent.canGoBack = nativeCanGoBack || canGoBack
        }

        if let urlString = dict["url"] as? String, let url = URL(string: urlString) {
            self.parent.currentURL = url
        }
    }

    private func handlePaymentResponse(_ message: WKScriptMessage) {
        if let response = message.body as? [String: Any] {
            NotificationCenter.default.post(
                name: Notification.Name("PaymentResponseReceived"),
                object: nil,
                userInfo: ["response": response]
            )
        }
    }

    private func handleSubmitButtonClicked() {
        let now = Date()
        if let lastTime = lastSubmitTime,
            now.timeIntervalSince(lastTime) < submitDebounceInterval
        {
            return
        }
        lastSubmitTime = now

        NotificationCenter.default.post(name: NSNotification.Name("SubmitButtonClicked"), object: nil)
    }

    private func handleElementFound(_ message: WKScriptMessage) {
        self.parent.isReady = true
    }

    private func handleInsertPrompt(_ message: WKScriptMessage) {
        if let body = message.body as? [String: Any],
            let prompt = body["prompt"] as? String
        {
            // Use coordinator directly
            Task {
                await self.parent.jsCoordinator.insertPrompt(prompt, editorType: .tiptap)
            }
        }
    }

    private func handleStartVoiceEntry() {
        NotificationCenter.default.post(name: Notification.Name("StartVoiceEntryNotification"), object: nil)
    }

    private func handleOpenExternalURL(_ message: WKScriptMessage) {
        if let body = message.body as? [String: Any],
            let urlString = body["url"] as? String,
            let url = URL(string: urlString)
        {
            Logger.shared.log("Opening external URL from JS: \(urlString)")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func handlePromotionButtonClicked(_ message: WKScriptMessage) {
        var userInfo: [String: Any] = [:]

        if let body = message.body as? [String: Any],
            let buttonClass = body["buttonClass"] as? String
        {
            userInfo["buttonClass"] = buttonClass
            Logger.shared.log("📊 Promotion button clicked with class: \(buttonClass)")
        }

        NotificationCenter.default.post(
            name: Notification.Name("PromotionButtonClicked"),
            object: nil,
            userInfo: userInfo
        )
    }

    private func handleManagePlanClicked() {
        NotificationCenter.default.post(name: Notification.Name("ManagePlanClicked"), object: nil)
    }

    private func handleGetSubscriptionsResponse(_ message: WKScriptMessage) {
        if let messageBody = message.body as? [String: Any],
            let response = messageBody["response"] as? [String: Any]
        {
            NotificationCenter.default.post(
                name: Notification.Name("getSubscriptionsResponseReceived"),
                object: response
            )
        }
    }
}

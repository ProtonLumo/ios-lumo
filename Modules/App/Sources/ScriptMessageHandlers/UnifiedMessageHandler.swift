import LumoCore
import WebKit

final class UnifiedMessageHandler: NSObject, WKScriptMessageHandler, WKMessageHandlerRegistering {
    enum MessageName: String, CaseIterable {
        case navigationState
        case paymentResponse
        case submitButtonClicked
        case elementFound
        case insertPrompt
        case startVoiceEntry
        case promotionButtonClicked
        case managePlanClicked
        case getSubscriptionsResponseReceived
        case openExternalURL
    }

    let parent: WebView
    private var lastSubmitTime: Date?
    private let submitDebounceInterval: TimeInterval = 0.5

    init(_ parent: WebView) {
        self.parent = parent
    }

    // MARK: - WKMessageHandlerRegistering

    func registerForAll(in configuration: WKWebViewConfiguration) {
        MessageName.allCases.forEach { message in
            configuration.userContentController.add(self, name: message.rawValue)
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageName = MessageName(rawValue: message.name)
        Logger.shared.log("📨 Received message: \(message.name)")

        switch messageName {
        case .navigationState:
            handleNavigationState(message)
        case .paymentResponse:
            handlePaymentResponse(message)
        case .submitButtonClicked:
            handleSubmitButtonClicked()
        case .elementFound:
            handleElementFound(message)
        case .insertPrompt:
            handleInsertPrompt(message)
        case .startVoiceEntry:
            handleStartVoiceEntry()
        case .promotionButtonClicked:
            handlePromotionButtonClicked(message)
        case .managePlanClicked:
            handleManagePlanClicked()
        case .getSubscriptionsResponseReceived:
            handleGetSubscriptionsResponse(message)
        case .openExternalURL:
            handleOpenExternalURL(message)
        case .none:
            Logger.shared.log("⚠️ Unknown message: \(message.name)")
        }
    }

    // MARK: - Private

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

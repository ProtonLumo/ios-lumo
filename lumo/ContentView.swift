import SwiftUI
import WebKit
import os.log
import ProtonUIFoundations
import Speech

enum WebViewAction: Equatable {
    case postSubscription(payload: [String: Any])
    case postToken(payload: [String: Any])
    case getPlans
    case getSubscriptions

    static func == (lhs: WebViewAction, rhs: WebViewAction) -> Bool {
        switch (lhs, rhs) {
        case (.postSubscription(let lhsPayload), .postSubscription(let rhsPayload)):
            return NSDictionary(dictionary: lhsPayload).isEqual(to: rhsPayload)
        case (.postToken(let lhsPayload), .postToken(let rhsPayload)):
            return NSDictionary(dictionary: lhsPayload).isEqual(to: rhsPayload)
        case (.getPlans, .getPlans):
            return true
        case (.getSubscriptions, .getSubscriptions):
            return true
        default:
            return false
        }
    }
}

class PaymentSheetDelegate: NSObject, PaymentSheetViewModelDelegate {
    var contentView: ContentView?
    var onSubscriptionRequest: (([String: Any]) -> Void)?
    var onTokenRequest: (([String: Any]) -> Void)?
    var onGetPlansRequest: (() -> Void)?
    var onGetSubscriptionsRequest: (() -> Void)?

    func subscriptionRequest(payload: [String: Any]) {
        Logger.shared.log("PaymentSheet delegate called with subscription payload: \(payload)")
        onSubscriptionRequest?(payload)
    }
    
    func tokenRequest(payload: [String: Any]) {
        Logger.shared.log("PaymentSheet delegate called with token payload: \(payload)")
        onTokenRequest?(payload)
    }
    
    func getPlansRequest() {
        Logger.shared.log("PaymentSheet delegate called to get plans")
        onGetPlansRequest?()
    }
    
    func getSubscriptionsRequest() {
        Logger.shared.log("PaymentSheet delegate called to get subscriptions")
        onGetSubscriptionsRequest?()
    }
}

struct ContentView: View {
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeProvider: ThemeProvider
    
    // MARK: - State Properties
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var jsCoordinator = WebViewCoordinator()
    @State private var isLoading = true
    @State private var webViewIsActive = true
    @State private var webViewReady = false

    @State private var isInsertingText = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var webViewAction: WebViewAction? = nil
    @State private var paymentResponse: [String: Any]? = nil
    @State private var webViewCanGoBack: Bool = false
    @State private var currentWebViewURL: URL? = nil
    @State private var webViewReference: WKWebView? = nil
    @State private var networkError: Bool = false
    @State private var processTerminated: Bool = false
    @State private var paymentHandler: PaymentHandler? = nil
    @State private var isSubmittingSpeech = false
    @State private var webProcessTerminated = false
    @State private var processTerminationCount = 0
    @State private var lastTerminationTime: Date? = nil
    @State private var showLoader = false
    @State private var showCurrentPlans = false
    @State private var currentPlansViewModel: CurrentPlansViewModel?
    @State private var isGenerating = false

    // MARK: - Constants
    private let paymentSheetDelegate = PaymentSheetDelegate()
    private let brandPurple = Color(hex: 0x6D4AFF)
    private let recordingColor = Color(hex: 0xE67553)
    
    // Use ThemeProvider for consistent theme
    private var isDarkMode: Bool {
        themeProvider.isDarkMode
    }
    
    private var darkModeBackgroundColor: Color {
        Color(hex: 0x16141c)
    }
    
    private let safetyTimeoutDuration: TimeInterval = 3.0

    init() {
        paymentSheetDelegate.onSubscriptionRequest = { [weak paymentSheetDelegate] payload in
            paymentSheetDelegate?.contentView?.performPostSubscription(payload: payload)
        }
        
        paymentSheetDelegate.onTokenRequest = { [weak paymentSheetDelegate] payload in
            paymentSheetDelegate?.contentView?.performPostToken(payload: payload)
        }
        
        paymentSheetDelegate.onGetPlansRequest = { [weak paymentSheetDelegate] in
            paymentSheetDelegate?.contentView?.performGetPlans()
        }
        
        paymentSheetDelegate.onGetSubscriptionsRequest = { [weak paymentSheetDelegate] in
            paymentSheetDelegate?.contentView?.performGetSubscriptions()
        }
    }

    private var shouldShowBackButton: Bool {
        guard let url = currentWebViewURL?.absoluteString else { return false }
        // Only show back button when on account pages (outside main Lumo app)
        return url.contains(Config.ACCOUNT_BASE_URL)
    }
    
    private var backgroundColor: Color {
        // Use isDarkMode state which is kept in sync by updateThemeState()
        return isDarkMode ? darkModeBackgroundColor : Color.white
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Background color that adapts to theme
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if shouldShowBackButton {
                    LumoNavigationBar(
                        currentURL: currentWebViewURL,
                        onBackButtonPress: handleBackButtonPress,
                        isDarkMode: isDarkMode
                    )
                }

                WebView(url: URL.lumoBase!,
                        isReady: $webViewReady,
                        jsCoordinator: jsCoordinator,
                        action: $webViewAction,
                        canGoBack: $webViewCanGoBack,
                        currentURL: $currentWebViewURL,
                        webViewStore: $webViewReference,
                        networkError: $networkError,
                        processTerminated: $processTerminated,
                        paymentHandler: $paymentHandler)
                    .onAppear { Logger.shared.log("WebView appeared") }
                    .onDisappear {
                        Logger.shared.log("ContentView disappeared")
                        webViewIsActive = false
                        performWebViewCleanup()
                    }
            }

            if !webViewReady && (showLoader || currentWebViewURL == nil) {
                LoadingView(isDarkMode: isDarkMode)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: !webViewReady && (showLoader || currentWebViewURL == nil))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + safetyTimeoutDuration) {
                            if !webViewReady {
                                Logger.shared.log("⚠️ LoadingView safety timeout reached - forcing webViewReady=true")
                                webViewReady = true
                                showLoader = false
                            }
                        }
                    }
            }

            if networkError {
                NetworkErrorView(
                    onRetry: handleRetryConnection,
                    isProcessTermination: processTerminated
                )
            }

            if speechRecognizer.isRecording || isSubmittingSpeech {
                SpeechRecorderView(
                    speechRecognizer: speechRecognizer,
                    recordingDuration: $recordingDuration,
                    isSubmitting: $isSubmittingSpeech,
                    stopRecording: stopRecording,
                    formatDuration: formatDuration,
                    brandPurple: brandPurple
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isSubmittingSpeech)
            }
            
            // Permission alert overlay
            PermissionAlertOverlay(
                isPresented: $speechRecognizer.showingPermissionAlert,
                permissionType: "microphone",
                onSettings: {
                    openAppSettings()
                }
            )
        }
        .onChange(of: currentWebViewURL) { newURL in
            handleURLChange(newURL)
        }
        .onChange(of: webViewReady) { isReady in
            if isReady { 
                showLoader = false
                
                // Mark coordinator as ready - it will automatically process pending commands
                jsCoordinator.markReady()
                
                // Setup initial scripts
                Task {
                    await jsCoordinator.setupInitialScripts()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartVoiceEntryNotification"))) { _ in
            if !speechRecognizer.isRecording {
                speechRecognizer.startRecording()
                startRecordingTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Check if microphone permissions have changed since we last checked
            // This helps handle cases where user went to Settings and changed permissions
            checkMicrophonePermissionOnForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ThemeChangedFromWeb"))) { _ in
            updateThemeState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            updateThemeState()
            // End background task when app becomes active
            BackgroundTaskManager.shared.endBackgroundTask()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Start background task when app goes to background
            // This gives us ~30 seconds to finish any ongoing generation
            Logger.shared.log("📱 App will resign active - starting background task to complete AI generation")
            BackgroundTaskManager.shared.beginBackgroundTask()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            Logger.shared.log("📱 App entered background")
            if BackgroundTaskManager.shared.hasActiveBackgroundTask {
                Logger.shared.log("✅ Background task is active - generation can continue")
            }
        }
        .onChange(of: colorScheme) { newValue in
            // Only respond to colorScheme changes if we're on system theme
            let themeManager = ThemeManager.shared
            Logger.shared.log("📱 System colorScheme changed to: \(newValue == .dark ? "dark" : "light")")
            Logger.shared.log("📱 Current theme setting: \(themeManager.currentTheme.rawValue == 0 ? "light" : themeManager.currentTheme.rawValue == 1 ? "dark" : "system")")
            
            if themeManager.currentTheme == .system {
                Logger.shared.log("📱 Theme is .system, updating appearance with new value...")
                // Pass the new colorScheme value directly to avoid timing issues
                themeManager.updateSystemThemeMode(newValue == .dark)
                themeProvider.updateTheme(systemColorScheme: newValue)
            } else {
                Logger.shared.log("📱 Theme is explicitly set, ignoring system change")
            }
        }
        .onAppear {
            Logger.shared.log("ContentView appeared")
        
            updateThemeState()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }

            setupNotificationObservers()
        }
        .sheet(isPresented: $showCurrentPlans) {
            
            if let viewModel = currentPlansViewModel {
                CurrentPlansView(viewModel: viewModel)
            } else {
                ZStack {
                    Color(Theme.color.backgroundNorm)
                        .ignoresSafeArea()
                    
                    VStack {
                        //MARK: Modal presentation close button
                        ZStack {
                            Text(String(localized: "current.plans.title"))
                                .font(.system(size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(Theme.color.textNorm)
                            HStack {
                                Spacer()
                                Button {
                                    showCurrentPlans = false
                                } label: {
                                    Image(uiImage: Theme.icon.cross)
                                        .tint(Theme.color.textNorm)
                                }
                                .padding(Theme.spacing.extraLarge)
                            }
                        }
                        
                        HStack {
                            Text(String(localized: "current.plans.section.title"))
                                .font(.system(size: 15))
                                .fontWeight(.regular)
                                .foregroundColor(Theme.color.textWeak)
                                .padding(.horizontal, Theme.spacing.medium)
                            Spacer()
                        }
                        
                        SubscriptionLoadingView(loadingMessage: String(localized: "current.plans.loading.message"))
                    }
                }
            }
        }
    }

    // MARK: - Back Navigation
    private func handleBackButtonPress() {
        guard let currentURL = currentWebViewURL else {
            Logger.shared.log("No current URL available for back navigation")
            return
        }
        
        safeWebViewOperation { webView in
            DispatchQueue.main.async {
                self.showLoader = true
                self.webViewReady = false
            }
            
            webView.stopLoading()
            webView.loadLumoBase()
        }
    }
    
    // MARK: - URL Change Handler
    
    private func handleURLChange(_ newURL: URL?) {
        let urlString = newURL?.absoluteString ?? "nil"
        guard newURL != nil else { return }
        
        // Check if this is a signup URL without plan parameter and redirect if needed
        if urlString.hasPrefix("\(Config.ACCOUNT_BASE_URL)/lumo/signup") &&
           !urlString.contains("?plan=") && !urlString.contains("&plan=") {
            Logger.shared.log("🔄 CONTENTVIEW: Detected signup URL without plan parameter: \(urlString)")
            
            let modifiedURLString = urlString.addingQueryParameter("plan", value: "free")
            
            if let modifiedURL = URL(string: modifiedURLString) {
                safeWebViewOperation { webView in
                    webView.load(URLRequest(url: modifiedURL))
                }
                return
            }
        }
        
        webViewCanGoBack = urlString.contains(Config.ACCOUNT_BASE_URL)
    }

    private func safeWebViewOperation(_ operation: (WKWebView) -> Void) {
        guard let webView = webViewReference, webView.superview != nil else {
            Logger.shared.log("WebView reference is nil or WebView has been removed from view hierarchy")
            return
        }

        operation(webView)
    }

    private func performWebViewCleanup() {
        safeWebViewOperation { webView in
            Logger.shared.log("Performing WebView cleanup")

            webView.stopLoading()
            webView.configuration.userContentController.removeAllUserScripts()

            let handlerNames = ["insertPrompt", "startVoiceEntry", "navigationState",
                                "paymentResponse", "elementFound", "showPayment"]

            for name in handlerNames {
                webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
            }

            webView.scrollView.zoomScale = 1.0
            webView.scrollView.setContentOffset(CGPoint.zero, animated: false)
            
            Task {
                let cleanupCommands: [JSCommand] = [
                    .simulateGarbageCollection,
                    .clearHistory
                ]
                
                let results = await self.jsCoordinator.executeBatch(cleanupCommands)
                let successCount = results.filter { $0.isSuccess }.count
                Logger.shared.log("✅ Cleanup: \(successCount)/\(cleanupCommands.count) successful")
                
                self.jsCoordinator.cleanup()
            }

            let cacheOnlyDataTypes: Set<String> = [
                WKWebsiteDataTypeDiskCache,
                WKWebsiteDataTypeMemoryCache,
                WKWebsiteDataTypeOfflineWebApplicationCache
            ]

            WKWebsiteDataStore.default().removeData(
                ofTypes: cacheOnlyDataTypes,
                modifiedSince: Date(timeIntervalSince1970: 0)) {
                DispatchQueue.main.async {
                    Logger.shared.log("Cleared cache data for process recovery, preserving auth cookies")
                    self.networkError = false
                    self.processTerminated = false
                    self.webViewReady = false

                    if let webView = self.webViewReference {
                        webView.loadLumoBaseWithCacheBusting()
                    }
                }
            }
        }
    }

    private func handleRetryConnection() {
        networkError = false
        processTerminated = false
        webViewReady = false

        safeWebViewOperation { webView in
            if processTerminated {
                webView.loadLumoBaseWithCacheBusting()
            } else if webView.url != nil {
                webView.reload()
            } else {
                webView.loadLumoBase()
            }
        }
    }

    // MARK: - Speech Recognition
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startRecordingTimer() {
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            recordingDuration += 1
        }
    }

    private func stopRecording(submitText: Bool) {
        recordingTimer?.invalidate()
        recordingTimer = nil

        if submitText && !speechRecognizer.transcribedText.isEmpty {
            
            if !isSubmittingSpeech {
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: 0.1)) {
                        self.isSubmittingSpeech = true
                    }
                }
            }

            let transcribedText = speechRecognizer.transcribedText

            DispatchQueue.global(qos: .userInitiated).async {
                self.speechRecognizer.stopRecording()
                
                DispatchQueue.main.async {
                    self.speechRecognizer.transcribedText = ""
                    self.isInsertingText = true
                    
                    Task {
                        let result = await self.jsCoordinator.insertPrompt(transcribedText, editorType: .tiptap)
                        
                        switch result {
                        case .success:
                            Logger.shared.log("✅ Voice transcription inserted successfully")
                            await self.observeTextInsertion()
                        case .failure(let error):
                            Logger.shared.log("❌ Failed to insert voice transcription: \(error.errorDescription ?? "")")
                            self.isInsertingText = false
                            self.isSubmittingSpeech = false
                        }
                    }
                }
            }
        } else {
            speechRecognizer.stopRecording()
            isSubmittingSpeech = false
        }
    }

    private func observeTextInsertion() async {
        Logger.shared.log("⏳ Waiting for text insertion to complete...")
        
        // Wait for DOM to update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        Logger.shared.log("✅ Text insertion completed")
        finishSpeechInsertion()
    }

    private func finishSpeechInsertion() {
        isSubmittingSpeech = false
        isInsertingText = false
    }

    // MARK: - Payment Handling
    fileprivate func performPostSubscription(payload: [String: Any]) {
        self.paymentResponse = nil
        self.webViewAction = .postSubscription(payload: payload)
    }
    
    fileprivate func performPostToken(payload: [String: Any]) {
        self.paymentResponse = nil
        self.webViewAction = .postToken(payload: payload)
    }
    
    fileprivate func performGetPlans() {
        self.paymentResponse = nil
        self.webViewAction = .getPlans
    }
    
    fileprivate func performGetSubscriptions() {
        self.paymentResponse = nil
        self.webViewAction = .getSubscriptions
    }

    private func handlePaymentResponse(_ response: [String: Any]) {
        guard let type = response["type"] as? String else { return }

        let success = response["success"] as? Bool ?? false

        switch type {
        case "subscription":
            if success {
                if let data = response["data"] as? [String: Any] {
                    Logger.shared.log("Subscription successful: \(data)")
                }
            } else {
                if let error = response["error"] as? String {
                    Logger.shared.log("Subscription error: \(error)")
                }
            }
        case "token":
            if success {
                if let data = response["data"] as? [String: Any] {
                    Logger.shared.log("Token successful: \(data)")
                }
            } else {
                if let error = response["error"] as? String {
                    Logger.shared.log("Token error: \(error)")
                }
            }
        case "plans":
            if success {
                if let data = response["data"] as? [String: Any] {
                    Logger.shared.log("Plans received: \(data)")
                }
            } else {
                if let error = response["error"] as? String {
                    Logger.shared.log("Plans fetch error: \(error)")
                }
            }
        case "subscriptions":
            if success {
                if let data = response["data"] as? [String: Any] {
                    Logger.shared.log("Subscriptions received: \(data)")
                }
            } else {
                if let error = response["error"] as? String {
                    Logger.shared.log("Subscriptions fetch error: \(error)")
                }
            }
        default:
            Logger.shared.log("Unknown payment response type: \(type)")
        }
    }

    // MARK: - Plans Handling
    private func fetchPlansAndShowPaymentSheet(isPromotionOffer: Bool = false) {
        paymentHandler?.fetchAndShowPaymentSheet(isPromotionOffer: isPromotionOffer)
    }

    // MARK: - Payment and Plans Handling
    
    private func showCurrentPlansView() {
        Logger.shared.log("🔧 showCurrentPlansView called")
        
        let viewModel = CurrentPlansViewModel(plansData: [])
        
        Task { @MainActor in
            viewModel.viewState = .loading
        }
        
        currentPlansViewModel = viewModel
        
        performGetSubscriptions()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            Task { @MainActor in
                if let currentViewModel = self.currentPlansViewModel,
                   currentViewModel.viewState == .loading {
                    Logger.shared.log("📋 Subscription fetch timeout - setting error state")
                    currentViewModel.viewState = .errorData
                }
            }
        }
        
        showCurrentPlans = true
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        setupPromptObserver()
        setupAppStateObserver()
        setupProcessTerminationObserver()
        setupDomainNavigationObserver()
        setupSessionSaveObserver()
    }
    
    private func updateThemeState() {
        let themeManager = ThemeManager.shared
        
        Logger.shared.log("📱 updateThemeState called: currentTheme=\(themeManager.currentTheme.rawValue), currentMode=\(themeManager.currentMode.rawValue), colorScheme=\(colorScheme == .dark ? "dark" : "light")")
        
        // Update system theme mode to keep ThemeManager in sync
        if themeManager.currentTheme == .system {
            themeManager.updateSystemThemeMode(colorScheme == .dark)
        }
        
        // Update the centralized ThemeProvider - this will propagate to all views
        themeProvider.updateTheme(systemColorScheme: colorScheme)
    }

    private func setupPromptObserver() {
        paymentSheetDelegate.contentView = self

        let notificationObservers: [(name: Notification.Name, handler: (Notification) -> Void)] = [
            (.init("LumoPromptReceived"), { notification in
                if let prompt = notification.userInfo?["prompt"] as? String {
                    Task {
                        let result = await self.jsCoordinator.insertPrompt(prompt, editorType: .tiptap)
                        
                        switch result {
                        case .success:
                            Logger.shared.log("✅ Widget prompt inserted successfully")
                        case .failure(let error):
                            Logger.shared.log("❌ Failed to insert widget prompt: \(error.errorDescription ?? "")")
                        }
                    }
                }
            }),


            (.init("PromotionButtonClicked"), { notification in
                let buttonClass = notification.userInfo?["buttonClass"] as? String
                let isPromotionOffer = buttonClass?.contains("lumo-bf2025-promotion") ?? false
                self.fetchPlansAndShowPaymentSheet(isPromotionOffer: isPromotionOffer)
            }),

            (.init("ManagePlanClicked"), { _ in
                Logger.shared.log("🔧 ManagePlanClicked notification received")
                self.showCurrentPlansView()
            }),

            (.init("PaymentResponseReceived"), { notification in
                if let response = notification.userInfo?["response"] as? [String: Any] {
                    self.paymentResponse = response
                    self.handlePaymentResponse(response)
                }
            }),
            
            (.init("getPlansResponseReceived"), { notification in
                if let response = notification.userInfo?["response"] as? [String: Any] {
                    let wrappedResponse: [String: Any] = ["type": "plans", "success": true, "data": response]
                    self.paymentResponse = wrappedResponse
                    self.handlePaymentResponse(wrappedResponse)
                }
            }),
            
            (.init("getSubscriptionsResponseReceived"), { notification in
                Logger.shared.log("📋 getSubscriptionsResponseReceived notification received")
                
                if let response = notification.userInfo?["response"] as? [String: Any] {
                    let wrappedResponse: [String: Any] = ["type": "subscriptions", "success": true, "data": response]
                    self.paymentResponse = wrappedResponse
                    self.handlePaymentResponse(wrappedResponse)
                    
                    // Update CurrentPlansViewModel if it's active
                    if let viewModel = self.currentPlansViewModel {
                        self.updateCurrentPlansViewModel(viewModel, with: response)
                    }
                } else if let response = notification.object as? [String: Any] {
                    let wrappedResponse: [String: Any] = ["type": "subscriptions", "success": true, "data": response]
                    self.paymentResponse = wrappedResponse
                    self.handlePaymentResponse(wrappedResponse)
                    
                    // Update CurrentPlansViewModel if it's active
                    if let viewModel = self.currentPlansViewModel {
                        self.updateCurrentPlansViewModel(viewModel, with: response)
                    }
                } else {
                    Logger.shared.log("📋 ERROR: No response data found in notification")
                    
                    // Set error state if no valid data received
                    if let viewModel = self.currentPlansViewModel {
                        Task { @MainActor in
                            viewModel.viewState = .errorData
                        }
                    }
                }
            }),
            
        ]

        for (name, handler) in notificationObservers {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main, using: handler)
        }
    }

    private func setupAppStateObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Logger.shared.log("📱 App became active")
            // WebViewCoordinator automatically handles pending commands when ready
        }
    }

    private func setupProcessTerminationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WebContentProcessDidTerminate"),
            object: nil,
            queue: .main
        ) { _ in
            let now = Date()

            if let lastTime = self.lastTerminationTime,
               now.timeIntervalSince(lastTime) < 60 {
                self.processTerminationCount += 1

                if self.processTerminationCount >= 3 {
                    self.performWebViewCleanup()

                    let cacheOnlyDataTypes: Set<String> = [
                        WKWebsiteDataTypeDiskCache,
                        WKWebsiteDataTypeMemoryCache,
                        WKWebsiteDataTypeOfflineWebApplicationCache
                    ]

                    WKWebsiteDataStore.default().removeData(
                        ofTypes: cacheOnlyDataTypes,
                        modifiedSince: Date(timeIntervalSince1970: 0)) {
                        DispatchQueue.main.async {
                            Logger.shared.log("Cleared cache data for process recovery, preserving auth cookies")
                            self.networkError = false
                            self.processTerminated = false
                            self.webViewReady = false

                            if let webView = self.webViewReference {
                                webView.loadLumoBaseWithCacheBusting()
                            }
                        }
                    }

                    self.processTerminationCount = 0
                }
            } else {
                self.processTerminationCount = 1
            }

            self.lastTerminationTime = now
            self.webProcessTerminated = true
        }
    }

    private func setupDomainNavigationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ImportantDomainNavigation"),
            object: nil,
            queue: .main
        ) { notification in
            // Handle important domain navigation
            if let isAccountToLumo = notification.userInfo?["isAccountToLumo"] as? Bool,
               isAccountToLumo == true {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.showLoader = true
                        self.webViewReady = false
                    }
                }
                return
            }

            if notification.userInfo?["url"] is String {
                let isCrossDomain = notification.userInfo?["isCrossDomain"] as? Bool ?? false

                if isCrossDomain {
                    self.showLoader = true
                    self.webViewReady = false
                }
            }
        }
    }

    private func setupSessionSaveObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SaveWebViewSession"),
            object: nil,
            queue: .main
        ) { _ in
            self.saveWebViewSession()
        }
    }
    
    private func saveWebViewSession() {
        safeWebViewOperation { webView in
            DispatchQueue.main.async { [weak webView] in
                guard let webView = webView else { return }
                let dataStore = webView.configuration.websiteDataStore
                
                dataStore.httpCookieStore.getAllCookies { cookies in
                    Logger.shared.log("Persisting \(cookies.count) cookies for next app launch")
                    
                    for cookie in cookies {
                        dataStore.httpCookieStore.setCookie(cookie) {
                            // Cookie has been persisted
                        }
                    }
                }
                
                // Also force a flush of other persistent data types
                let persistentDataTypes: Set<String> = [
                    WKWebsiteDataTypeLocalStorage,
                    WKWebsiteDataTypeSessionStorage,
                    WKWebsiteDataTypeIndexedDBDatabases,
                    WKWebsiteDataTypeWebSQLDatabases
                ]
                
                // Fetch all data to force synchronization to disk
                dataStore.fetchDataRecords(ofTypes: persistentDataTypes) { records in
                    Logger.shared.log("Synchronized \(records.count) persistent data records from ContentView")
                }
            }
        }
    }

    private func updateCurrentPlansViewModel(_ viewModel: CurrentPlansViewModel, with data: [String: Any]) {
        Logger.shared.log("Updating CurrentPlansViewModel with subscription data")
        
        // Convert the subscription data to CurrentSubscriptionResponse format
        var subscriptions: [CurrentSubscriptionResponse] = []
        
        // Check if data contains a Subscriptions array (matching the actual API response)
        if let subscriptionsArray = data["Subscriptions"] as? [[String: Any]] {
            for subscriptionData in subscriptionsArray {
                if let subscription = convertToCurrentSubscriptionResponse(subscriptionData) {
                    subscriptions.append(subscription)
                }
            }
        } else if let subscriptionsArray = data["subscriptions"] as? [[String: Any]] {
            // Fallback for lowercase 'subscriptions'
            for subscriptionData in subscriptionsArray {
                if let subscription = convertToCurrentSubscriptionResponse(subscriptionData) {
                    subscriptions.append(subscription)
                }
            }
        } else if let subscription = convertToCurrentSubscriptionResponse(data) {
            // Single subscription object
            subscriptions.append(subscription)
        } else {
            Logger.shared.log("No subscription data found in response")
        }
        
        // Update the existing view model instead of creating a new one
        Task { @MainActor in
            // Instead of updating the existing view model, create a new one with the data
            // This ensures SwiftUI properly observes the changes
            let newViewModel = CurrentPlansViewModel(plansData: subscriptions)
            self.currentPlansViewModel = newViewModel
            
            Logger.shared.log("Updated CurrentPlansViewModel with \(subscriptions.count) subscriptions")
        }
    }
    
    private func convertToCurrentSubscriptionResponse(_ data: [String: Any]) -> CurrentSubscriptionResponse? {
        // Extract required fields - handle both uppercase and lowercase field names
        let title = data["Title"] as? String ?? data["title"] as? String ?? data["Name"] as? String ?? data["name"] as? String
        let description = data["Description"] as? String ?? data["description"] as? String ?? "Subscription"
        
        guard let finalTitle = title else {
            Logger.shared.log("Missing required title/name field in subscription data")
            return nil
        }
        
        // Convert the subscription data to CurrentSubscriptionResponse
        return CurrentSubscriptionResponse(
            id: data["ID"] as? String ?? data["id"] as? String,
            name: data["Name"] as? String ?? data["name"] as? String,
            title: finalTitle,
            description: description,
            cycle: data["Cycle"] as? Int ?? data["cycle"] as? Int,
            cycleDescription: data["CycleDescription"] as? String ?? data["cycleDescription"] as? String,
            currency: data["Currency"] as? String ?? data["currency"] as? String,
            amount: data["Amount"] as? Int ?? data["amount"] as? Int,
            offer: data["Offer"] as? String ?? data["offer"] as? String,
            periodStart: data["PeriodStart"] as? Int ?? data["periodStart"] as? Int,
            periodEnd: data["PeriodEnd"] as? Int ?? data["periodEnd"] as? Int,
            createTime: data["CreateTime"] as? Int ?? data["createTime"] as? Int,
            couponCode: data["CouponCode"] as? String ?? data["couponCode"] as? String,
            discount: data["Discount"] as? Int ?? data["discount"] as? Int,
            renewDiscount: data["RenewDiscount"] as? Int ?? data["renewDiscount"] as? Int,
            renewAmount: data["RenewAmount"] as? Int ?? data["renewAmount"] as? Int,
            renew: data["Renew"] as? Int ?? data["renew"] as? Int,
            external: data["External"] as? Int ?? data["external"] as? Int,
            entitlements: [], // TODO: Convert entitlements if needed
            decorations: []   // TODO: Convert decorations if needed
        )
    }

    // MARK: - Permission Handling
    
    private func openAppSettings() {
        Logger.shared.log("Opening app settings for permission change")
        
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
    }
    
    private func checkMicrophonePermissionOnForeground() {
        guard speechRecognizer.showingPermissionAlert else { return }
        
        Logger.shared.log("App came to foreground - checking if microphone permission changed")
        
        // Check if permission status has changed
        PermissionManager.shared.checkForPermissionChanges { [ self] granted in
            if granted {
                Logger.shared.log("Microphone permission was granted while app was in background")
                DispatchQueue.main.async {
                    // Hide the permission alert since permission is now granted
                    self.speechRecognizer.showingPermissionAlert = false
                    
                    // Don't automatically start recording - let user tap the voice button again
                    // This provides better UX control
                }
            } else {
                Logger.shared.log("Microphone permission still denied after app foreground")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


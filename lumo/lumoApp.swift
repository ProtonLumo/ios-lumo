import SwiftUI

@main
struct lumoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LumoPromptReceived"))) { notification in
                    if let prompt = notification.userInfo?["prompt"] as? String {
                        Logger.shared.log("App received prompt: \(prompt)", category: "AppDelegate")
                    }
                }
                .onOpenURL { url in
                    Logger.shared.log("Scene received URL: \(url)", category: "AppDelegate")
                    _ = appDelegate.application(UIApplication.shared, open: url, options: [:])
                }
                .onChange(of: scenePhase) { newPhase in
                    Logger.shared.log("Scene phase changed to: \(newPhase)", category: "AppDelegate")
                    
                    switch newPhase {
                    case .background:
                        Logger.shared.log("App entering background - saving WebView session", category: "AppDelegate")
                        // Notify ContentView to save WebView session
                        NotificationCenter.default.post(
                            name: Notification.Name("SaveWebViewSession"),
                            object: nil
                        )
                        
                        // Give additional time for session data to be written to disk
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            Logger.shared.log("Session save grace period completed", category: "AppDelegate")
                        }
                    case .active:
                        Logger.shared.log("App became active - checking for preserved authentication", category: "AppDelegate")
                    case .inactive:
                        Logger.shared.log("App became inactive", category: "AppDelegate")
                    @unknown default:
                        Logger.shared.log("Unknown scene phase: \(newPhase)", category: "AppDelegate")
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Logger.shared.log("App launched with options: \(String(describing: launchOptions))", category: "AppDelegate")
        
        // Initialize Apple Subscription Manager
        Task {
            _ = AppleSubscriptionManager.shared
            Logger.shared.log("AppleSubscriptionManager initialized", category: "AppDelegate")
        }
        
        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
            Logger.shared.log("App launched with URL: \(url)", category: "AppDelegate")
            handleURL(url)
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        handleURL(url)
        return true
    }
    
    private func handleURL(_ url: URL) {
        
        guard url.scheme == "lumo" else { 
            Logger.shared.log("Invalid URL scheme: \(url.scheme ?? "nil")", category: "AppDelegate")
            return 
        }
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            
            if let prompt = components.queryItems?.first(where: { $0.name == "prompt" })?.value {
                DispatchQueue.main.async {
                    Logger.shared.log("Broadcasting LumoPromptReceived notification", category: "AppDelegate")
                    NotificationCenter.default.post(
                        name: Notification.Name("LumoPromptReceived"),
                        object: nil,
                        userInfo: ["prompt": prompt]
                    )
                }
            } else {
                Logger.shared.log("No prompt found in URL", category: "AppDelegate")
            }
        } else {
            Logger.shared.log("Failed to parse URL components", category: "AppDelegate")
        }
    }
}

import SwiftUI
import ProtonUIFoundations
import UIKit
import Lottie

struct LoadingView: View {
    // State to track the current message index
    @State private var currentMessageIndex = 0
    
    // Timer to rotate messages
    @State private var messageTimer: Timer? = nil
    
    // Cat-themed loading messages
    private let loadingMessages = [
        String(localized: "app.loading.attention"),
        String(localized: "app.loading.battingbars"),
        String(localized: "app.loading.chasingawaydatabrokers"),
        String(localized: "app.loading.chasingmice"),
        String(localized: "app.loading.knockingoffshelves"),
        String(localized: "app.loading.meowing"),
        String(localized: "app.loading.napping"),
        String(localized: "app.loading.plotting"),
        String(localized: "app.loading.purringengines"),
        String(localized: "app.loading.sharpening"),
        String(localized: "app.loading.stretching"),
    ]
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
                       
            
            VStack(spacing: 20) {
                
                LottieView(name: "lumo-loader")
                        .frame(width: 180, height: 180)
                
                // Message with fade transition
                Text(loadingMessages[currentMessageIndex])
                    .font(.footnote)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(height: 40) // Fixed height to prevent layout shifts
                    .transition(.opacity)
                    .id("loadingMessage\(currentMessageIndex)") // Force view recreation on change
                    .animation(.easeInOut(duration: 0.5), value: currentMessageIndex)
            }
            .padding(.horizontal, 30)
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        .zIndex(100) // Keep high z-index to stay on top
        .onAppear {
            // Start with a random message
            currentMessageIndex = Int.random(in: 0..<loadingMessages.count)
            
            // Set up timer to change messages every 3.5 seconds
            messageTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
                withAnimation {
                    // Get a new random index that's different from the current one
                    var newIndex: Int
                    repeat {
                        newIndex = Int.random(in: 0..<loadingMessages.count)
                    } while newIndex == currentMessageIndex && loadingMessages.count > 1
                    
                    currentMessageIndex = newIndex
                }
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            messageTimer?.invalidate()
            messageTimer = nil
        }
    }
}

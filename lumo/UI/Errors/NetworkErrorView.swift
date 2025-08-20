import SwiftUI
import ProtonUIFoundations

struct NetworkErrorView: View {
    var onRetry: () -> Void
    var isProcessTermination: Bool = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: isProcessTermination ? "exclamationmark.triangle" : "wifi.slash")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.color.notificationError)
                
                Text(String(localized: isProcessTermination ? 
                           "app.error.process.title" : 
                           "app.error.network.title"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.color.notificationError)
                    .multilineTextAlignment(.center)
                
                Text(String(localized: isProcessTermination ? 
                           "app.error.process.message" : 
                           "app.error.network.message"))
                    .font(.body)
                    .foregroundColor(Theme.color.textWeak)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: onRetry) {
                    Text(String(localized: "app.error.retry"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Theme.color.brandNorm)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
            }
            .padding(24)
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
        .zIndex(200)
    }
} 

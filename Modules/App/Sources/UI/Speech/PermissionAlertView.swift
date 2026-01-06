import SwiftUI
import ProtonUIFoundations

struct PermissionAlertView: View {
    let permissionType: String
    let onSettings: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundColor(Theme.color.notificationError)
            
            Text(String(localized: "permission.microphone.denied.title"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Theme.color.textNorm)
                .multilineTextAlignment(.center)
            
            Text(String(localized: "permission.microphone.denied.message"))
                .font(.body)
                .foregroundColor(Theme.color.textWeak)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            
            // Buttons
            VStack(spacing: 12) {
                // Go to Settings button
                Button(action: onSettings) {
                    Text(String(localized: "permission.settings.button"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.color.brandNorm)
                        .cornerRadius(8)
                }
                
                // Cancel button
                Button(action: onDismiss) {
                    Text(String(localized: "permission.cancel.button"))
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Theme.color.textWeak)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.color.backgroundNorm)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal, 32)
    }
}

struct PermissionAlertOverlay: View {
    @Binding var isPresented: Bool
    let permissionType: String
    let onSettings: () -> Void
    
    var body: some View {
        if isPresented {
            ZStack {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Allow dismissing by tapping background
                        isPresented = false
                    }
                
                // Alert content
                PermissionAlertView(
                    permissionType: permissionType,
                    onSettings: {
                        onSettings()
                        isPresented = false
                    },
                    onDismiss: {
                        isPresented = false
                    }
                )
            }
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.3), value: isPresented)
            .zIndex(999)
        }
    }
} 
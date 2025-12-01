import SwiftUI
import ProtonUIFoundations

struct LockdownModeWarningView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.color.textAccent)
                
                Text("Lockdown Mode is Active")
                    .font(.headline)
                    .foregroundColor(Theme.color.textNorm)
                
                Text("Conversation syncing is disabled due to Lockdown Mode restrictions.")
                    .font(.body)
                    .foregroundColor(Theme.color.textWeak)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add this app to Lockdown Mode exceptions")
                        .font(.subheadline)
                        .foregroundColor(Theme.color.textNorm)
                    
                    Text("Settings > Privacy & Security > Lockdown Mode")
                        .font(.caption)
                        .foregroundColor(Theme.color.textWeak)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Theme.color.backgroundSecondary)
                .cornerRadius(12)
                
                VStack(spacing: 12) {
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Open Settings")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.color.textAccent)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Not Now")
                            .font(.body)
                            .foregroundColor(Theme.color.textWeak)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
            }
            .padding(.all, 32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.color.backgroundNorm)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
            )
            .padding(.horizontal, 32)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: true)
        .zIndex(999)
    }
}

#Preview {
    LockdownModeWarningView(onDismiss:  { })
}

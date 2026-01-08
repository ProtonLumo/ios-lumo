import ProtonUIFoundations
import SwiftUI

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

                Text(String(localized: "app.lockdown.title"))
                    .font(.headline)
                    .foregroundColor(Theme.color.textNorm)

                Text(String(localized: "app.lockdown.message"))
                    .font(.body)
                    .foregroundColor(Theme.color.textWeak)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "app.lockdown.exceptions.title"))
                        .font(.subheadline)
                        .foregroundColor(Theme.color.textNorm)

                    Text(String(localized: "app.lockdown.exceptions.path"))
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
                        Text(String(localized: "permission.settings.button"))
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
                        Text(String(localized: "app.lockdown.dismiss"))
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
    LockdownModeWarningView(onDismiss: {})
}

import ProtonUIFoundations
import SwiftUI

public struct PermissionAlertOverlay: View {
    let onSettings: () -> Void
    let onDismiss: () -> Void

    public init(onSettings: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onSettings = onSettings
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            PermissionAlertView(
                onSettings: onSettings,
                onDismiss: onDismiss
            )
        }
        .transition(.opacity)
        .zIndex(999)
    }
}

private struct PermissionAlertView: View {
    let onSettings: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash")
                .font(.system(size: 48))
                .foregroundColor(Theme.color.notificationError)

            Text(L10n.Permission.microphoneTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Theme.color.textNorm)
                .multilineTextAlignment(.center)

            Text(L10n.Permission.microphoneMessage)
                .font(.body)
                .foregroundColor(Theme.color.textWeak)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            VStack(spacing: 12) {
                Button(action: onSettings) {
                    Text(L10n.Permission.openSettings)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.color.brandNorm)
                        .cornerRadius(8)
                }

                Button(action: onDismiss) {
                    Text(L10n.Permission.cancel)
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

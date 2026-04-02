import SwiftUI

extension View {
    public func onReceive(
        notificationCenter: NotificationCenter = .default,
        notification: NSNotification.Name,
        perform: @escaping () -> Void
    ) -> some View {
        onReceive(
            notificationCenter.publisher(for: notification),
            perform: { _ in perform() }
        )
    }
}

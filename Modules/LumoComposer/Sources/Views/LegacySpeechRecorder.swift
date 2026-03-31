import Combine
import LumoCore
import SwiftUI

/// Thin wrapper around `SpeechStateStore` for the legacy WebView ContentView.
/// Will be removed when ContentView migrates to native composer.
@available(*, deprecated, message: "Remove together with ContentView WebView integration")
@MainActor
public final class LegacySpeechRecorder: ObservableObject {
    private let store: SpeechStateStore
    private var cancellable: AnyCancellable?

    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var isPermissionDenied: Bool = false

    public var state: SpeechStateStore.State {
        store.state
    }

    public init(urlOpener: any URLOpenerProtocol) {
        self.store = SpeechStateStore(service: SpeechRecordingServiceFactory.make(), urlOpener: urlOpener)

        cancellable = store.$state.sink { [weak self] state in
            self?.isActive = state.isActive
            self?.isPermissionDenied = state.isPermissionDenied
        }
    }

    public func startRecording() {
        store.send(action: .startRecording)
    }

    public func submitRecording() {
        store.send(action: .submitRecording)
    }

    public func cancelRecording() {
        store.send(action: .cancelRecording)
    }

    public func dismissPermissionAlert() {
        store.send(action: .dismissPermissionAlert)
    }

    public func openSettings() {
        store.send(action: .openSettings)
    }

    public func setTranscriptionHandler(_ handler: @escaping (String) async -> Void) {
        store.onTranscriptionComplete = handler
    }
}

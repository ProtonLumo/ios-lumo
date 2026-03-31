import Combine
import Foundation

@MainActor
public final class SpeechStateStore: StateStore {
    public enum State: Equatable {
        case idle
        case permissionDenied
        case recording(RecordingViewState)
        case submitting(RecordingViewState)
    }

    enum Action: Sendable {
        case startRecording
        case submitRecording
        case cancelRecording
        case dismissPermissionAlert
        // Internal — dispatched from stream listener / timer:
        case _transcriptionUpdated(String)
        case _audioLevelsUpdated([CGFloat])
        case _durationTick
        case _isOnDeviceChanged(Bool)
        case _permissionDenied
        case _failed
    }

    @Published var state: State = .idle

    /// Async closure invoked when recording is submitted.
    /// WebView: `insertPrompt()` + sleep. Native composer: set `currentText`, return immediately.
    var onTranscriptionComplete: ((String) async -> Void)?

    private let service: any SpeechRecordingServiceProtocol
    private var streamTask: Task<Void, Never>?
    private var durationTask: Task<Void, Never>?

    init(service: any SpeechRecordingServiceProtocol) {
        self.service = service
    }

    func send(action: Action) async {
        switch action {
        case .startRecording:
            let permission = await service.requestPermissions()
            guard permission == .granted else {
                state = .permissionDenied
                return
            }

            do {
                try await service.startRecording()
            } catch {
                return
            }

            state = .recording(.initial)

            durationTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { break }
                    await send(action: ._durationTick)
                }
            }

            streamTask = Task {
                let currentUpdates = service.updates
                for await update in currentUpdates {
                    guard !Task.isCancelled else { break }
                    switch update {
                    case .transcriptionUpdated(let text):
                        await send(action: ._transcriptionUpdated(text))
                    case .audioLevelsUpdated(let levels):
                        await send(action: ._audioLevelsUpdated(levels))
                    case .isOnDeviceChanged(let value):
                        await send(action: ._isOnDeviceChanged(value))
                    case .failed(.permissionDenied):
                        await send(action: ._permissionDenied)
                    case .failed:
                        await send(action: ._failed)
                    }
                }
            }

        case .submitRecording:
            guard case .recording(let viewState) = state else { return }
            state = .submitting(viewState)
            durationTask?.cancel()
            streamTask?.cancel()
            await service.stopRecording()
            await onTranscriptionComplete?(viewState.transcription)
            state = .idle

        case .cancelRecording:
            durationTask?.cancel()
            streamTask?.cancel()
            state = .idle
            service.cancel()

        case .dismissPermissionAlert:
            state = .idle

        case ._transcriptionUpdated(let text):
            guard case .recording(var viewState) = state else { return }
            viewState.transcription = text
            state = .recording(viewState)

        case ._audioLevelsUpdated(let levels):
            guard case .recording(var viewState) = state else { return }
            viewState.audioLevels = levels
            state = .recording(viewState)

        case ._durationTick:
            guard case .recording(var viewState) = state else { return }
            viewState.duration += 1
            state = .recording(viewState)

        case ._isOnDeviceChanged(let value):
            guard case .recording(var viewState) = state else { return }
            viewState.isOnDevice = value
            state = .recording(viewState)

        case ._permissionDenied:
            durationTask?.cancel()
            streamTask?.cancel()
            state = .permissionDenied
            service.cancel()

        case ._failed:
            durationTask?.cancel()
            streamTask?.cancel()
            state = .idle
            service.cancel()
        }
    }
}

// MARK: - State helpers

extension SpeechStateStore.State {
    var recordingViewState: RecordingViewState? {
        switch self {
        case .idle, .permissionDenied: nil
        case .recording(let state), .submitting(let state): state
        }
    }

    var isActive: Bool {
        switch self {
        case .idle: false
        case .permissionDenied, .recording, .submitting: true
        }
    }

    var isPermissionDenied: Bool {
        if case .permissionDenied = self { return true }
        return false
    }
}

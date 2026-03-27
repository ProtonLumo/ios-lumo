import AVFoundation

@testable import LumoComposer

final class AudioSessionSpy: AudioSession {
    var stubbedSetCategoryError: (any Error)?
    var stubbedSetActiveError: (any Error)?

    struct SetCategoryParams: Equatable {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let options: AVAudioSession.CategoryOptions
    }

    struct SetActiveParams: Equatable {
        let active: Bool
        let options: AVAudioSession.SetActiveOptions
    }

    private(set) var setCategoryCalls: [SetCategoryParams] = []
    private(set) var setActiveCalls: [SetActiveParams] = []
    private(set) var setPreferredSampleRateCalls: [Double] = []
    private(set) var setPreferredIOBufferDurationCalls: [TimeInterval] = []

    // MARK: - AudioSession

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        setCategoryCalls.append(.init(category: category, mode: mode, options: options))

        if let error = stubbedSetCategoryError {
            throw error
        }
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        setActiveCalls.append(.init(active: active, options: options))

        if let error = stubbedSetActiveError {
            throw error
        }
    }

    func setPreferredSampleRate(_ sampleRate: Double) throws {
        setPreferredSampleRateCalls.append(sampleRate)
    }

    func setPreferredIOBufferDuration(_ duration: TimeInterval) throws {
        setPreferredIOBufferDurationCalls.append(duration)
    }
}

import Lottie
import Testing

@testable import LumoComposer

struct LottieTestingTrait: TestTrait, TestScoping {
    let pausedAt: AnimationProgressTime

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await LottieEnvironment.$pausedAt.withValue(pausedAt, operation: function)
    }
}

extension Trait where Self == LottieTestingTrait {
    static func lottiePaused(at progress: AnimationProgressTime) -> Self {
        .init(pausedAt: progress)
    }
}

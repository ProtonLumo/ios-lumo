import Foundation
import Testing

@testable import LumoComposer

struct UUIDEnvironmentTrait: TestTrait, TestScoping {
    let uuid: UUID

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await UUIDEnvironment.$uuid.withValue({ uuid }, operation: function)
    }
}

extension Trait where Self == UUIDEnvironmentTrait {
    static func stubbedUUID(_ uuid: UUID) -> Self {
        .init(uuid: uuid)
    }
}

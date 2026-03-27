import Testing
import WebKit

@testable import LumoApp

@MainActor
struct AppVersionOverrideTests {
    @Test
    func scriptLoadsAndSubstitutesVersion() throws {
        let script = try #require(
            JSBridgeManager.shared.createUserScript(
                .appversionOverride,
                parameters: ["APP_VERSION": "1.2.9"],
                injectionTime: .atDocumentStart,
            )
        )

        #expect(script.source.contains("x-pm-appversion"))
        #expect(script.source.contains("ios-lumo@1.2.9"))
        #expect(!script.source.contains("{{APP_VERSION}}"))
    }

    @Test
    func scriptInjectsAtDocumentStart() {
        let script = JSBridgeManager.shared.createUserScript(
            .appversionOverride,
            parameters: ["APP_VERSION": "1.0.0"],
            injectionTime: .atDocumentStart,
        )

        #expect(script?.injectionTime == .atDocumentStart)
    }
}

import Foundation
import Testing

@testable import LumoApp

struct BundleShortVersionTests {
    @Test
    func bundleShortVersionMatchesSemanticFormat() {
        let version = Bundle.main.bundleShortVersion
        let match = version.wholeMatch(of: /\d+\.\d+\.\d+/)

        #expect(match != nil, "Expected format X.Y.Z but got '\(version)'")
    }
}

import Difference
import Testing

/// Assert that two values are equal, showing differences with the Difference library when they don't match.
///
/// This is a Swift Testing-compatible version of the Difference library's enhanced equality assertion.
/// When values don't match, it provides a detailed diff output to help identify the differences.
///
/// Uses `Issue.record()` which is the recommended approach for custom assertions in Swift Testing.
///
/// - Parameters:
///   - expected: The expected value
///   - received: The received/actual value
///   - sourceLocation: The source location where the assertion is called (automatically captured)
func expectDiff<T: Equatable>(
    _ expected: @autoclosure () throws -> T,
    _ received: @autoclosure () throws -> T,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    do {
        let expectedValue = try expected()
        let receivedValue = try received()

        guard expectedValue == receivedValue else {
            let differences = diff(expectedValue, receivedValue).joined(separator: "\n")
            Issue.record(
                "Found difference:\n\(differences)",
                sourceLocation: sourceLocation
            )
            return
        }
    } catch {
        Issue.record(
            "Caught error while testing: \(error)",
            sourceLocation: sourceLocation
        )
    }
}

import Foundation
import Testing

@testable import LumoComposer

struct RecognitionErrorMapperTests {
    struct TestCase {
        let domain: String
        let code: Int
        let expected: RecognitionErrorMapper.Action?
        let label: String
    }

    @Test(arguments: [
        // kLSRErrorDomain
        TestCase(domain: "kLSRErrorDomain", code: 102, expected: nil, label: "assetsNotInstalled"),
        TestCase(domain: "kLSRErrorDomain", code: 201, expected: .permissionDenied, label: "siriDisabled"),
        TestCase(domain: "kLSRErrorDomain", code: 300, expected: nil, label: "initializationFailed"),
        TestCase(domain: "kLSRErrorDomain", code: 301, expected: .ignore, label: "cancelled"),
        TestCase(domain: "kLSRErrorDomain", code: 9999, expected: nil, label: "unknownLSRCode"),

        // kAFAssistantErrorDomain
        TestCase(domain: "kAFAssistantErrorDomain", code: 203, expected: nil, label: "recognitionFailure"),
        TestCase(domain: "kAFAssistantErrorDomain", code: 1100, expected: nil, label: "alreadyActive"),
        TestCase(domain: "kAFAssistantErrorDomain", code: 1101, expected: nil, label: "connectionInvalidated"),
        TestCase(domain: "kAFAssistantErrorDomain", code: 1107, expected: .ignore, label: "connectionInterrupted"),
        TestCase(domain: "kAFAssistantErrorDomain", code: 1110, expected: .ignore, label: "noSpeechDetected"),
        TestCase(domain: "kAFAssistantErrorDomain", code: 1700, expected: .permissionDenied, label: "notAuthorized"),
        TestCase(domain: "kAFAssistantErrorDomain", code: 9999, expected: nil, label: "unknownAFCode"),

        // Unknown domain
        TestCase(domain: "com.example.unknown", code: 42, expected: nil, label: "unknownDomain")
    ])
    func action(testCase: TestCase) {
        let error = NSError(domain: testCase.domain, code: testCase.code)
        #expect(RecognitionErrorMapper.action(for: error) == testCase.expected)
    }
}

import Testing
import WebKit

@testable import LumoComposer

@MainActor
final class WebComposerScriptMessageHandlerTests {
    let composerBridge = WebComposerBridge()
    lazy var sut = WebComposerScriptMessageHandler(webComposerBridge: composerBridge)

    struct TestCase {
        let stateDict: [String: Any]
        let expectedState: WebComposerState
    }

    @Test
    func registerForAll_RegistersAllMessageNames() {
        let configuration = WKWebViewConfigurationSpy()
        let contentControllerSpy = configuration.stubbedUserContentController
        let allMessageNames = WebComposerScriptMessageHandler.MessageName.allCases

        #expect(contentControllerSpy.addCalls.isEmpty)

        sut.registerForAll(in: configuration)

        #expect(contentControllerSpy.addCalls.count == allMessageNames.count)

        zip(allMessageNames, contentControllerSpy.addCalls)
            .forEach { messageName, params in
                #expect(params.scriptMessageHandler === sut)
                #expect(params.name == messageName.rawValue)
            }
    }

    @Test(
        arguments: [
            TestCase(
                stateDict: [
                    "lumoMode": "Idle",
                    "modelTier": "auto",
                    "isGhostModeEnabled": false,
                    "isWebSearchEnabled": false,
                    "isCreateImageEnabled": false,
                    "isVisible": true,
                    "showTsAndCs": true,
                    "attachedFiles": [],
                    "featureFlags": [
                        "isImageGenEnabled": false,
                        "isModelSelectionEnabled": false,
                    ],
                ],
                expectedState: .init(
                    mode: .idle,
                    model: .auto,
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: false,
                    isCreateImageEnabled: false,
                    isVisible: true,
                    showTermsAndPrivacy: true,
                    attachedFiles: [],
                    featureFlags: .initial
                )
            ),
            TestCase(
                stateDict: [
                    "lumoMode": "Working",
                    "modelTier": "auto",
                    "isGhostModeEnabled": true,
                    "isWebSearchEnabled": true,
                    "isCreateImageEnabled": false,
                    "isVisible": false,
                    "showTsAndCs": false,
                    "attachedFiles": [
                        [
                            "id": "<file-123>",
                            "name": "document.pdf",
                            "type": "PDF",
                        ]
                    ],
                    "featureFlags": [
                        "isImageGenEnabled": true,
                        "isModelSelectionEnabled": true,
                    ],
                ],
                expectedState: .init(
                    mode: .working,
                    model: .auto,
                    isGhostModeEnabled: true,
                    isWebSearchEnabled: true,
                    isCreateImageEnabled: false,
                    isVisible: false,
                    showTermsAndPrivacy: false,
                    attachedFiles: [
                        File(id: "<file-123>", name: "document.pdf", type: .pdf, preview: .none)
                    ],
                    featureFlags: .init(isImageGenEnabled: true, isModelSelectionEnabled: true)
                )
            ),
        ]
    )
    func handleStateChange_EmitsStateUpdateToStateUpdates(testCase: TestCase) async {
        let stateTask = Task {
            var receivedStates: [WebComposerState] = []
            for await state in composerBridge.stateUpdates {
                receivedStates.append(state)
                if receivedStates.count == 1 {
                    break
                }
            }
            return receivedStates
        }
        let messageName = WebComposerScriptMessageHandler.MessageName.nativeComposerStateHandler

        sut.userContentController(
            WKUserContentController(),
            didReceive: WKScriptMessageStub(name: messageName.rawValue, body: testCase.stateDict)
        )

        let receivedStates = await stateTask.value

        #expect(receivedStates.count == 1)
        expectDiff(receivedStates.last, testCase.expectedState)
    }

    @Test
    func handleResult_WithErrorStatus_EmitsErrorToStream() async {
        let error = WebComposerError.tierLimit
        let resultDict: [String: Any] = [
            "status": "error",
            "error": error.rawValue,
        ]
        let messageName = WebComposerScriptMessageHandler.MessageName.nativeComposerHandler

        let errorTask = Task {
            var receivedErrors: [WebComposerError] = []
            for await error in composerBridge.errorUpdates {
                receivedErrors.append(error)
                if receivedErrors.count == 1 {
                    break
                }
            }
            return receivedErrors
        }

        sut.userContentController(
            WKUserContentController(),
            didReceive: WKScriptMessageStub(name: messageName.rawValue, body: resultDict)
        )

        let receivedErrors = await errorTask.value

        #expect(receivedErrors.count == 1)
        #expect(receivedErrors.first == error)
    }

    @Test
    func handleResult_WithSuccessStatus_DoesNotEmitError() async {
        let resultDict: [String: Any] = [
            "requestId": "123",
            "result": [
                "status": "success"
            ],
        ]
        let messageName = WebComposerScriptMessageHandler.MessageName.nativeComposerHandler

        let errorTask = Task {
            var receivedErrors: [WebComposerError] = []
            for await error in composerBridge.errorUpdates {
                receivedErrors.append(error)
                if receivedErrors.count == 1 {
                    break
                }
            }
            return receivedErrors
        }

        sut.userContentController(
            WKUserContentController(),
            didReceive: WKScriptMessageStub(name: messageName.rawValue, body: resultDict)
        )

        try? await Task.sleep(for: .milliseconds(50))

        errorTask.cancel()
        let receivedErrors = await errorTask.value

        #expect(receivedErrors.isEmpty)
    }

    @Test
    func handleResult_WithMalformedData_DoesNotEmitError() async {
        let resultDict: [String: Any] = [
            "invalidKey": "invalidValue"
        ]
        let messageName = WebComposerScriptMessageHandler.MessageName.nativeComposerHandler

        let errorTask = Task {
            var receivedErrors: [WebComposerError] = []
            for await error in composerBridge.errorUpdates {
                receivedErrors.append(error)
                if receivedErrors.count == 1 {
                    break
                }
            }
            return receivedErrors
        }

        sut.userContentController(
            WKUserContentController(),
            didReceive: WKScriptMessageStub(name: messageName.rawValue, body: resultDict)
        )

        try? await Task.sleep(for: .milliseconds(50))

        errorTask.cancel()
        let receivedErrors = await errorTask.value

        #expect(receivedErrors.isEmpty)
    }

    @Test
    func handleResult_WithMultipleErrors_EmitsAllToStream() async {
        let errors: [WebComposerError] = [
            .tierLimit,
            .generationError,
            .unknown,
        ]
        let messageName = WebComposerScriptMessageHandler.MessageName.nativeComposerHandler

        let errorTask = Task {
            var receivedErrors: [WebComposerError] = []
            for await error in composerBridge.errorUpdates {
                receivedErrors.append(error)
                if receivedErrors.count == errors.count {
                    break
                }
            }
            return receivedErrors
        }

        for error in errors {
            let resultDict: [String: Any] = [
                "status": "error",
                "error": error.rawValue,
            ]

            sut.userContentController(
                WKUserContentController(),
                didReceive: WKScriptMessageStub(name: messageName.rawValue, body: resultDict)
            )
        }

        let receivedErrors = await errorTask.value

        #expect(receivedErrors.count == errors.count)
        #expect(receivedErrors == errors)
    }
}

private final class WKScriptMessageStub: WKScriptMessage {
    private let _name: String
    private let _body: Any

    init(name: String, body: Any) {
        _name = name
        _body = body
        super.init()
    }

    override var name: String {
        _name
    }

    override var body: Any {
        _body
    }
}

private final class WKWebViewConfigurationSpy: WKWebViewConfiguration {
    let stubbedUserContentController = WKUserContentControllerSpy()

    // MARK: - WKWebViewConfiguration

    override var userContentController: WKUserContentController {
        get { stubbedUserContentController }
        set {}
    }
}

private final class WKUserContentControllerSpy: WKUserContentController {
    private(set) var addCalls: [(scriptMessageHandler: any WKScriptMessageHandler, name: String)] = []

    // MARK: - WKUserContentController

    override func add(_ scriptMessageHandler: any WKScriptMessageHandler, name: String) {
        addCalls.append((scriptMessageHandler, name))
    }
}

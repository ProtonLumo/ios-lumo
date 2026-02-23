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
                    "modelType": "Auto",
                    "isGhostModeEnabled": false,
                    "isWebSearchEnabled": false,
                    "isCreateImageEnabled": false,
                    "isVisible": true,
                    "showTsAndCs": true,
                    "attachedFiles": [],
                ],
                expectedState: .init(
                    mode: .idle,
                    modelType: .auto,
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: false,
                    isCreateImageEnabled: false,
                    isVisible: true,
                    showTermsAndPrivacy: true,
                    attachedFiles: []
                )
            ),
            TestCase(
                stateDict: [
                    "lumoMode": "Working",
                    "modelType": "Auto",
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
                ],
                expectedState: .init(
                    mode: .working,
                    modelType: .auto,
                    isGhostModeEnabled: true,
                    isWebSearchEnabled: true,
                    isCreateImageEnabled: false,
                    isVisible: false,
                    showTermsAndPrivacy: false,
                    attachedFiles: [
                        File(id: "<file-123>", name: "document.pdf", type: .pdf, preview: .none)
                    ]
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

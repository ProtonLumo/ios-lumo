import Testing
import WebKit

@testable import LumoComposer

@MainActor
final class WebComposerScriptMessageHandlerTests {
    let webBridge = WebComposerBridge()
    lazy var sut = WebComposerScriptMessageHandler(webBridge: webBridge)

    struct TestCase {
        let stateDict: [String: Any]
        let expectedState: WebComposerState
    }

    @Test(
        arguments: [
            TestCase(
                stateDict: [
                    "lumoMode": "Idle",
                    "isGhostModeEnabled": false,
                    "isWebSearchEnabled": false,
                    "isVisible": true,
                    "showTsAndCs": true,
                    "attachedFiles": [],
                ],
                expectedState: .init(
                    mode: .idle,
                    isGhostModeEnabled: false,
                    isWebSearchEnabled: false,
                    isVisible: true,
                    showTermsAndPrivacy: true,
                    attachedFiles: []
                )
            ),
            TestCase(
                stateDict: [
                    "lumoMode": "Working",
                    "isGhostModeEnabled": true,
                    "isWebSearchEnabled": true,
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
                    isGhostModeEnabled: true,
                    isWebSearchEnabled: true,
                    isVisible: false,
                    showTermsAndPrivacy: false,
                    attachedFiles: [
                        File(id: "<file-123>", name: "document.pdf", type: .pdf)
                    ]
                )
            ),
        ]
    )
    func handleStateChange_EmitsStateUpdateToStateUpdates(testCase: TestCase) async {
        let stateTask = Task {
            var receivedStates: [WebComposerState] = []
            for await state in webBridge.stateUpdates {
                receivedStates.append(state)
                if receivedStates.count == 1 {
                    break
                }
            }
            return receivedStates
        }

        sut.userContentController(
            WKUserContentController(),
            didReceive: WKScriptMessageStub(name: "nativeComposerStateHandler", body: testCase.stateDict)
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

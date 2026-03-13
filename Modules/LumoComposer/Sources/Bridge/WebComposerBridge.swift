import LumoCore
import WebKit

/// Errors that can occur during bridge operations.
public enum WebComposerBridgeError: Error, Equatable, LocalizedError {
    /// JavaScript evaluation failed for the given command
    case evaluatingJSFailed(WebComposerBridge.Command)

    /// WebView is not attached - call `attach(to:)` first
    case webViewNotAttached

    // MARK: - LocalizedError

    public var errorDescription: String? {
        String(localized: L10n.Error.generic)
    }
}

public final class WebComposerBridge: WebComposerAttaching, WebComposerBridging, WebComposerStateReceiving, WebComposerErrorReceiving {
    private let (stream, continuation) = AsyncStream.makeStream(of: WebComposerState.self)
    private let (errorStream, errorContinuation) = AsyncStream.makeStream(of: WebComposerError.self)

    /// Commands that can be sent to the WebView's JavaScript layer.
    public enum Command: Equatable {
        case sendPrompt(String)
        case stopResponse
        case uploadFiles([FileUploadData])
        case openProtonDrive
        case openSketch
        case toggleWebSearch
        case toggleCreateImage
        case changeModelTier(WebComposerState.ModelTier)
        case previewAttachment(id: String)
        case removeAttachment(id: String)

        /// JavaScript code to execute for this command.
        ///
        /// Generates a call to `window.nativeComposerApi` with a unique request ID.
        var rawString: String {
            let id = UUIDEnvironment.uuid().uuidString
            let command: String

            switch self {
            case .sendPrompt(let prompt):
                command = "sendPrompt('\(id)', '\(prompt.jsEscaped)');"
            case .stopResponse:
                command = "abortPrompt('\(id)');"
            case .uploadFiles(let files):
                let filesJSON =
                    files
                    .map { "{ base64: '\($0.base64.jsEscaped)', name: '\($0.name.jsEscaped)' }" }
                    .joined(separator: ", ")
                command = "uploadFiles('\(id)', [\(filesJSON)]);"
            case .openProtonDrive:
                command = "openProtonDrive('\(id)');"
            case .openSketch:
                command = "openSketch('\(id)');"
            case .toggleWebSearch:
                command = "toggleWebSearch('\(id)');"
            case .toggleCreateImage:
                command = "toggleCreateImage('\(id)');"
            case .changeModelTier(let modelTier):
                command = "changeModelTier('\(id)', '\(modelTier.rawValue)');"
            case .previewAttachment(let attachmentId):
                command = "previewFile('\(id)', '\(attachmentId)');"
            case .removeAttachment(let attachmentId):
                command = "removeFileEvent('\(id)', '\(attachmentId)');"
            }

            return "window.nativeComposerApi?.\(command)"
        }
    }

    public init() {}

    weak var webView: WebViewProtocol?

    // MARK: - WebComposerAttaching

    public func attach(to webView: WebViewProtocol) {
        self.webView = webView
    }

    // MARK: - WebComposerBridging

    public func sendPrompt(_ text: String) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.sendPrompt(text))
    }

    public func stopResponse() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.stopResponse)
    }

    public func toggleWebSearch() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.toggleWebSearch)
    }

    public func uploadFiles(_ files: [FileUploadData]) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.uploadFiles(files))
    }

    public func openProtonDrive() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.openProtonDrive)
    }

    public func openSketch() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.openSketch)
    }

    public func toggleCreateImage() async throws(WebComposerBridgeError) {
        try await executeJavaScript(.toggleCreateImage)
    }

    public func changeModelTier(_ model: WebComposerState.ModelTier) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.changeModelTier(model))
    }

    public func removeAttachment(id: String) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.removeAttachment(id: id))
    }

    public func previewAttachment(id: String) async throws(WebComposerBridgeError) {
        try await executeJavaScript(.previewAttachment(id: id))
    }

    public var stateUpdates: AsyncStream<WebComposerState> { stream }

    public var errorUpdates: AsyncStream<WebComposerError> { errorStream }

    // MARK: - WebComposerStateReceiving

    /// Processes state updates received from the WebView's JavaScript layer.
    ///
    /// **Data flow:** JavaScript → WKScriptMessage → Dictionary → `WebComposerState` → AsyncStream
    ///
    /// Decoding failures are silently ignored to maintain stable bridge communication.
    public func handleStateChange(state: [String: Any]) {
        guard let webState = decode(response: state, model: WebComposerState.self) else {
            return
        }

        continuation.yield(webState)
    }

    // MARK: - WebComposerErrorReceiving

    public func handleError(_ errorResponse: [String: Any]) {
        guard let response = decode(response: errorResponse, model: ComposerErrorResponse.self) else {
            return
        }

        errorContinuation.yield(response.error)
    }

    // MARK: - Private

    /// Executes a JavaScript command in the attached WebView.
    ///
    /// - Parameter command: Command to execute
    /// - Throws: `WebComposerBridgeError` if WebView not attached or execution fails
    private func executeJavaScript(_ command: Command) async throws(WebComposerBridgeError) {
        guard let webView else {
            throw .webViewNotAttached
        }

        do {
            try await webView.evaluateJavaScript(
                command.rawString,
                in: .none,
                contentWorld: .page
            )
        } catch {
            throw .evaluatingJSFailed(command)
        }
    }

    private func decode<Model: Decodable>(response: [String: Any], model: Model.Type) -> Model? {
        guard
            let jsonData = try? JSONSerialization.data(withJSONObject: response),
            let model = try? JSONDecoder().decode(Model.self, from: jsonData)
        else {
            return nil
        }

        return model
    }
}

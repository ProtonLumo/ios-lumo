import Combine

public final class WidgetPromptReceiver: ObservableObject {
    private let continuation: AsyncStream<String>.Continuation
    public let prompts: AsyncStream<String>

    public init() {
        (prompts, continuation) = AsyncStream.makeStream(of: String.self)
    }

    public func receive(_ prompt: String) {
        continuation.yield(prompt)
    }
}

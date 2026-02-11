import Combine

@MainActor
public protocol StateStore: ObservableObject where Action: Sendable {
    associatedtype State
    associatedtype Action
    associatedtype Effect

    var state: State { get set }

    @discardableResult
    func send(action: Action) async -> Effect
}

extension StateStore {
    func send(action: Action) {
        Task {
            await send(action: action)
        }
    }
}

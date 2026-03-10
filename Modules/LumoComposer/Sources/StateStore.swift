import Combine

@MainActor
protocol StateStore: ObservableObject where Action: Sendable {
    associatedtype State
    associatedtype Action

    var state: State { get set }

    func send(action: Action) async
}

extension StateStore {
    func send(action: Action) {
        Task {
            await send(action: action)
        }
    }
}

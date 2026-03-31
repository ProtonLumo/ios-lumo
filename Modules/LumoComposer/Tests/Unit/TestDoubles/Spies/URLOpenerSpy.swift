import Foundation
import LumoCore

@MainActor
final class URLOpenerSpy: URLOpenerProtocol {
    private(set) var callAsFunctionInvokedWithURL: [URL] = []
    private(set) var callAsFunctionInvoked: [(url: URL, completion: (Bool) -> Void)] = []

    func callAsFunction(_ url: URL) {
        callAsFunctionInvokedWithURL.append(url)
    }

    func callAsFunction(_ url: URL, completion: @escaping (Bool) -> Void) {
        callAsFunctionInvoked.append((url, completion))
    }
}

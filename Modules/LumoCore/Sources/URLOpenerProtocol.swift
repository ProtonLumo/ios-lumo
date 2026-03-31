import SwiftUI

public protocol URLOpenerProtocol {
    func callAsFunction(_ url: URL)
    func callAsFunction(_ url: URL, completion: @escaping (_ accepted: Bool) -> Void)
}

extension OpenURLAction: URLOpenerProtocol {}

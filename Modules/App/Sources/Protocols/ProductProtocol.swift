import Foundation
import StoreKit

/// Protocol that matches Apple's Product interface so that we don't depend on
/// the actual Product struct
public protocol ProductProtocol: Hashable, Sendable {
    var displayName: String { get }
    var description: String { get }
    var displayPrice: String { get }
    var price: Decimal { get }
    var id: String { get }
    func currency() -> String
}

public protocol ProtonTransactionProviding: Sendable {
    var id: UInt64 { get }
    var originalID: UInt64 { get }
    var productID: String { get }
    var price: Decimal? { get }
    var userTransactionUUID: UUID? { get }
    var currencyIdentifier: String? { get }
}

public struct ProtonTransaction: ProtonTransactionProviding {
    public var id: UInt64
    public var originalID: UInt64
    public var productID: String
    public var price: Decimal?
    public var userTransactionUUID: UUID?
    public var currencyIdentifier: String?
}

extension Product: ProductProtocol {}

extension Transaction {

    public func toProtonTransaction() -> ProtonTransaction {
        ProtonTransaction(
            id: id,
            originalID: originalID,
            productID: productID,
            price: price,
            userTransactionUUID: appAccountToken,
            currencyIdentifier: currency?.identifier)
    }
}

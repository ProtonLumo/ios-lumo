
public struct Token: Codable, DictionaryConvertible {
    public let amount: Int
    public let currency: String
    public let payment: PaymentReceipt?
    public let paymentMethodID: String?
}

public struct PaymentReceipt: Codable, Equatable, DictionaryConvertible {
    public let details: ReceiptDetails
    public let type: String
}

public struct ReceiptDetails: Codable, Equatable, DictionaryConvertible {
    public let bundleID: String
    public let productID: String
    public let receipt: String
    public let transactionID: String
}

import Foundation
import StoreKit

public enum StoreKitReceiptManagerError: Error {
    case unableToExtractReceiptData
}

public protocol StoreKitReceiptManagerProviding {
    static func fetchPurchaseReceipt() throws -> String
}

public final class StoreKitReceiptManager: StoreKitReceiptManagerProviding {

    public static func fetchPurchaseReceipt() throws -> String {
        guard let url = Bundle.main.appStoreReceiptURL, let data = try? Data(contentsOf: url) else {
            Logger.shared.log("StoreKit error: impossible to get receipt data")
            throw StoreKitReceiptManagerError.unableToExtractReceiptData
        }

        return data.base64EncodedString()
    }
}

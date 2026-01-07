import Foundation
import StoreKit

enum StoreKitReceiptManagerError: Error {
    case unableToExtractReceiptData
}

protocol StoreKitReceiptManagerProviding {
    static func fetchPurchaseReceipt() throws -> String
}

final class StoreKitReceiptManager: StoreKitReceiptManagerProviding {
    static func fetchPurchaseReceipt() throws -> String {
        guard let url = Bundle.main.appStoreReceiptURL, let data = try? Data(contentsOf: url) else {
            Logger.shared.log("StoreKit error: impossible to get receipt data")
            throw StoreKitReceiptManagerError.unableToExtractReceiptData
        }

        return data.base64EncodedString()
    }
}

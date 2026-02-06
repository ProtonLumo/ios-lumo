import Foundation

extension Decimal {
    func formattedPrice(currencyCode: String) -> String {
        formatted(.currency(code: currencyCode).presentation(.narrow).rounded())
    }
}

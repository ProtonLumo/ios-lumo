import Foundation
import StoreKit
import SwiftUI

// MARK: - Dictionary Extensions
public extension Dictionary {
    func toJsonData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
    }
}

// MARK: - JSONDecoder Extensions
public extension JSONDecoder.KeyDecodingStrategy {
    static var lowerCamelCase: JSONDecoder.KeyDecodingStrategy {
        .custom { keys in
            let lastKey = keys.last!
            
            // Handle ID and UUID special cases
            if lastKey.stringValue == "ID" || lastKey.stringValue == "UUID" {
                return AnyKey(stringValue: lastKey.stringValue.lowercased())!
            }
            
            // Handle standard camelCase conversion
            let currentKey = lastKey.stringValue
            guard let firstChar = currentKey.first else {
                return lastKey
            }
            
            return AnyKey(stringValue: firstChar.lowercased() + currentKey.dropFirst())!
        }
    }
}

// MARK: - CodingKey Implementation
public struct AnyKey: CodingKey {
    public let stringValue: String
    public let intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Sequence Extensions
extension Sequence where Element == AvailablePlan {
    func identifiersForAppleInstances() -> [String] {
        flatMap { $0.instances }
            .compactMap { $0.vendors.apple?.productID }
    }

    func modelsMatchingProducts(in products: any Sequence<Product>) -> [ComposedPlan] {
        flatMap { plan in
            plan.instances.map { (plan, $0) }
        }
        .compactMap { plan, instance -> ComposedPlan? in
            guard let matchingProduct = products.first(where: { $0.id == instance.vendors.apple?.productID }) else { 
                return nil 
            }
            
            return ComposedPlan(plan: plan, instance: instance, product: matchingProduct)
        }
    }
}

// MARK: - Product Extensions
extension Product {
    public func currency() -> String {
        return self.priceFormatStyle.currencyCode
    }
}

// MARK: - String Extensions
extension String {
    var capitalizedFirst: String {
        guard !isEmpty else { return self }
        
        let firstLetter = self.prefix(1).capitalized
        let remainingLetters = self.dropFirst()
        return firstLetter + remainingLetters
    }
    
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: UI Extensions

extension View {
    func animate(duration: CGFloat, _ execute: @escaping () -> Void) async {
        await withCheckedContinuation { continuation in
            withAnimation(.linear(duration: duration)) {
                execute()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                continuation.resume()
            }
        }
    }
}

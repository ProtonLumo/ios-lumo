import Foundation
import StoreKit

public final class PlansComposer: @unchecked Sendable {

    public var mostExpensivePlan: ComposedPlan?
    public var uuidString: String = ""

    private var storeProducts: [Product] = []
    private var availablePlans: [AvailablePlan] = []
    private let queue = DispatchQueue(label: "paymentsV2.plansComposer.syncQueue")

    private let payload: [String: Any]

    public init(payload: [String: Any]) {
        self.payload = payload
        do{
            try decodePayload()
        } catch {
            Logger.shared.log("Failed to decode Proton plans: \(payload)")
        }
    }

    private func getStoreProducts(_ plans: [String]) async throws -> [Product] {

        do {
            storeProducts = try await Product.products(for: plans)
            return storeProducts
        } catch {
            Logger.shared.log("Fetch product from StoreKit: Failure")
            throw error
        }
    }

    public func fetchAvailablePlans() async throws -> [ComposedPlan] {
        storeProducts = try await getStoreProducts(availablePlans.identifiersForAppleInstances())
        let matchedPlans = availablePlans.modelsMatchingProducts(in: storeProducts)
        mostExpensivePlan = matchedPlans.sorted { $0.pricePerMonth > $1.pricePerMonth }.first
        return matchedPlans
    }

    public func availableDiscount(comparedTo plan: ComposedPlan) -> Int? {
        mostExpensivePlan.flatMap { plan.discount(comparedTo: $0) }
    }

    public func matchPlanToStoreProduct(_ productId: String) -> ComposedPlan? {
        if storeProducts.isEmpty || availablePlans.isEmpty {
            debugPrint("no store products or available plans found, fetch them before calling this function")
            return nil
        }

        let products = storeProducts.filter { $0.id == productId }

        return availablePlans.modelsMatchingProducts(in: products).first
    }

    public func storeProductWithId(_ id: String) -> Product? {
        storeProducts.filter { $0.id == id }.first
    }

    // MARK: Private
    private func decodePayload() throws {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .lowerCamelCase

            let jsonData = try payload.toJsonData()
            let plans = try decoder.decode(AvailablePlans.self, from: jsonData)
            availablePlans = plans.plans
            uuidString = plans.uuid
        } catch {
            throw PaymentSheetError.errorCovertingPayload
        }
    }
}

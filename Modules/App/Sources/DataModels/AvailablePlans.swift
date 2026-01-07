import Foundation

struct AvailablePlans: Decodable, Hashable, Sendable {
    let uid: String
    let uuid: String
    let plans: [AvailablePlan]
}

struct AvailablePlan: Decodable, Hashable, Identifiable, Sendable {
    let description: String?
    let instances: [PlanInstance]
    let name: String?
    let state: Int
    let type: Int?
    let title: String
    let features: Int
    let entitlements: [Entitlement]
    let decorations: [Decoration]
    let id: String
    let services: Int

    static func empty() -> Self {
        AvailablePlan(
            description: nil,
            instances: [],
            name: nil,
            state: 0,
            type: nil,
            title: "",
            features: 0,
            entitlements: [],
            decorations: [],
            id: "",
            services: 0
        )
    }
}

public struct PlanInstance: Decodable, Hashable, Equatable, Sendable {
    public let price: [Price]
    public let description: String
    public let cycle: Int
    public let periodEnd: Int
    public let vendors: Vendors
}

public struct Price: Decodable, Hashable, Equatable, Identifiable, Sendable {
    public let current: Int
    public let currency: String
    public let id: String
}

public struct Vendors: Decodable, Hashable, Equatable, Sendable {
    public let apple: Vendor?
}

public struct Vendor: Decodable, Hashable, Equatable, Sendable {
    public let productID: String?
    public let customerID: String?
}

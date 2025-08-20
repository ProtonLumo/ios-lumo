import Foundation

public struct AvailablePlans: Decodable, Hashable, Sendable {

    public let uid: String
    public let uuid: String
    public let plans: [AvailablePlan]
}

public struct AvailablePlan: Decodable, Hashable, Identifiable, Sendable {

    public let description: String?
    public let instances: [PlanInstance]
    public let name: String?
    public let state: Int
    public let type: Int?
    public let title: String
    public let features: Int
    public let entitlements: [Entitlement]
    public let decorations: [Decoration]
    public let id: String
    public let services: Int

    public static func empty() -> Self {
        AvailablePlan(description: nil,
                      instances: [],
                      name: nil,
                      state: 0,
                      type: nil,
                      title: "",
                      features: 0,
                      entitlements: [],
                      decorations: [],
                      id: "",
                      services: 0)
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

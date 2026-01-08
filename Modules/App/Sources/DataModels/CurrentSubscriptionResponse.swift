struct CurrentSubscriptionResponse: Decodable, Hashable, Identifiable, Sendable {
    let id: String?
    let name: String?
    let title: String
    let description: String
    let cycle: Int?
    let cycleDescription: String?
    let currency: String?
    let amount: Int?
    let offer: String?
    let periodStart: Int?
    let periodEnd: Int?
    let createTime: Int?
    let couponCode: String?
    let discount: Int?
    let renewDiscount: Int?
    let renewAmount: Int?
    let renew: Int?
    let external: Int?
    let entitlements: [Entitlement]
    let decorations: [Decoration]
}

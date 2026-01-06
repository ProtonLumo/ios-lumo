
public struct CurrentSubscriptionResponse: Decodable, Hashable, Identifiable, Sendable {

    public let id: String?
    public let name: String?
    public let title: String
    public let description: String
    public let cycle: Int?
    public let cycleDescription: String?
    public let currency: String?
    public let amount: Int?
    public let offer: String?
    public let periodStart: Int?
    public let periodEnd: Int?
    public let createTime: Int?
    public let couponCode: String?
    public let discount: Int?
    public let renewDiscount: Int?
    public let renewAmount: Int?
    public let renew: Int?
    public let external: Int?
    public let entitlements: [Entitlement]
    public let decorations: [Decoration]

    public init(id: String?,
                name: String?,
                title: String,
                description: String,
                cycle: Int?,
                cycleDescription: String?,
                currency: String?,
                amount: Int?,
                offer: String?,
                periodStart: Int?,
                periodEnd: Int?,
                createTime: Int?,
                couponCode: String?,
                discount: Int?,
                renewDiscount: Int?,
                renewAmount: Int?,
                renew: Int?,
                external: Int?,
                entitlements: [Entitlement],
                decorations: [Decoration]) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.cycle = cycle
        self.cycleDescription = cycleDescription
        self.currency = currency
        self.amount = amount
        self.offer = offer
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.createTime = createTime
        self.couponCode = couponCode
        self.discount = discount
        self.renewDiscount = renewDiscount
        self.renewAmount = renewAmount
        self.renew = renew
        self.external = external
        self.entitlements = entitlements
        self.decorations = decorations
    }
}

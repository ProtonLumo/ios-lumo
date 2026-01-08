
public struct CreateSubscription: Codable, DictionaryConvertible {

    public let amount: Int?
    public let paymentMethodID: String?
    public let payments: [String]?
    public let paymentToken: String?

    public let cycle: Int
    public let currency: String?
    public let currencyID: Int?
    public let plans: [String: Int]?
    public let planIDs: [Int]?
    public let codes: [String]?
    public let couponCode: String?
    public let giftCode: String?

    init(amount: Int? = nil,
         paymentMethodID: String? = nil,
         payments: [String]? = nil,
         paymentToken: String?,
         cycle: Int,
         currency: String?,
         currencyID: Int? = nil,
         plans: [String : Int]?,
         planIDs: [Int]? = nil,
         codes: [String]? = nil,
         couponCode: String? = nil,
         giftCode: String? = nil) {
        self.amount = amount
        self.paymentMethodID = paymentMethodID
        self.payments = payments
        self.paymentToken = paymentToken
        self.cycle = cycle
        self.currency = currency
        self.currencyID = currencyID
        self.plans = plans
        self.planIDs = planIDs
        self.codes = codes
        self.couponCode = couponCode
        self.giftCode = giftCode
    }
}

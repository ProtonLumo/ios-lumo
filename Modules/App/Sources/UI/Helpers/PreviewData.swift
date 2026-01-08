
public struct PreviewsData {
#if DEBUG
    static func descriptionEntitlements() -> [Entitlement] {
        return [Entitlement.description(DescriptionEntitlement(type: "description", text: "10 VPN connections", iconName: "shield")),
                Entitlement.description(DescriptionEntitlement(type: "description", text: "Highest VPN speed", iconName: "rocket")),
                Entitlement.description(DescriptionEntitlement(type: "description", text: "5 users", iconName: "user"))]
    }

    static func progressEntitlements() -> [Entitlement] {
        return [Entitlement.progress(ProgressEntitlement(type: "progress", text: "0.1 GB of 1 GB", min: 0, max: 10, current: 1)),
                Entitlement.progress(ProgressEntitlement(type: "progress", text: "0.6 GB of 1 GB", min: 0, max: 10, current: 6)),
                Entitlement.progress(ProgressEntitlement(type: "progress", text: "0.9 GB of 1 GB", min: 0, max: 10, current: 9))]
    }

    static func allEntitlements() -> [Entitlement] {
        return descriptionEntitlements() + progressEntitlements()
    }

    static let currentSub = CurrentSubscriptionResponse(id: "asd123qwd12d",
                                                        name: "iosvpn_bundle2022_12_usd_auto_recurring",
                                                        title: "Visionary",
                                                        description: "Current plan",
                                                        cycle: 1,
                                                        cycleDescription: "a month",
                                                        currency: "EUR",
                                                        amount: 9999,
                                                        offer: nil,
                                                        periodStart: 1724842249,
                                                        periodEnd: 1756374649,
                                                        createTime: 1724842249,
                                                        couponCode: nil,
                                                        discount: nil,
                                                        renewDiscount: 20,
                                                        renewAmount: 7499,
                                                        renew: 1,
                                                        external: 0,
                                                        entitlements: [Entitlement.description(DescriptionEntitlement(type: "description", text: "10 VPN connections", iconName: "shield")),
                                                                       Entitlement.description(DescriptionEntitlement(type: "description", text: "Highest VPN speed", iconName: "rocket")),
                                                                       Entitlement.description(DescriptionEntitlement(type: "description", text: "5 users", iconName: "user")),
                                                                       Entitlement.progress(ProgressEntitlement(type: "progress", text: "0.6 GB of 1 GB", min: 0, max: 10, current: 6))],
                                                        decorations: [])

    static let freePlan = CurrentSubscriptionResponse(id: "asd123qwd12d",
                                                      name: nil,
                                                      title: "Proton Free",
                                                      description: "Current plan",
                                                      cycle: nil,
                                                      cycleDescription: nil,
                                                      currency: nil,
                                                      amount: nil,
                                                      offer: nil,
                                                      periodStart: nil,
                                                      periodEnd: nil,
                                                      createTime: nil,
                                                      couponCode: nil,
                                                      discount: nil,
                                                      renewDiscount: nil,
                                                      renewAmount: nil,
                                                      renew: 0,
                                                      external: 0,
                                                      entitlements: PreviewsData.allEntitlements(),
                                                      decorations: [])
#endif
}

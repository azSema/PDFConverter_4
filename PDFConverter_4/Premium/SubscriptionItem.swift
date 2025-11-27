import SwiftUI

enum PaywallID: String {
    case main
    case onboarding
}

struct SubscriptionItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var periodly: String
    var pricePerPeriod: String
    var pricePerWeek: String
    
    var subtitle: String {
        "MOCK subtitle"
    }
    
    var isTrial: Bool {
        title == "week"
    }
}

extension SubscriptionItem {
    static func mocks(_ id: PaywallID) -> [Self] {
        id == .main
        ? [
            .init(id: "w",
                         title: "Weakly",
                         periodly: "week",
                         pricePerPeriod: "4.99/week",
                         pricePerWeek: "Total $4.99/week"),
            .init(id: "m",
                         title: "Monthly",
                         periodly: "month",
                         pricePerPeriod: "$12.99/month",
                         pricePerWeek: "Total $3.24/week"),
            .init(id: "y",
                         title: "Yearly",
                         periodly: "year",
                         pricePerPeriod: "$39.99/year",
                         pricePerWeek: "Total $0.83/week"),
            .init(id: "u",
                         title: "Lifetime",
                         periodly: "lifetime",
                         pricePerPeriod: "59.99",
                         pricePerWeek: "Limited Time Offer")
        ]
        : [
            .init(id: "w",
                         title: "Weakly",
                         periodly: "week",
                         pricePerPeriod: "4.99/week",
                         pricePerWeek: "Total $4.99/week")
        ]
    }
}

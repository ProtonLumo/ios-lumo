import Foundation

struct FeatureRowModel: Hashable {
    let icon: String
    let text: String

    private var components: [String] = []

    var title: String {
        return components[0]
    }

    var free: String {
        return components[1]
    }

    var plus: String {
        return components[2]
    }

    var iconURL: URL? {
        URL(string: "https://lumo-api.proton.me/payments/v5/resources/icons/" + icon)
    }

    init(icon: String, text: String) {
        self.icon = icon
        self.text = text
        components = text.components(separatedBy: "::")
    }
}

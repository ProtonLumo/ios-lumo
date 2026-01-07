import Foundation

struct FeatureRowModel: Hashable {
    let icon: String

    private var components: [String] = []

    var title: String {
        components[0]
    }

    var free: String {
        components[1]
    }

    var plus: String {
        components[2]
    }

    var iconURL: URL? {
        URL(string: "https://lumo-api.proton.me/payments/v5/resources/icons/" + icon)
    }

    init(icon: String, text: String) {
        self.icon = icon
        components = text.components(separatedBy: "::")
    }
}

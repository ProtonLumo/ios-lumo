import Foundation

enum Config {
    static let ACCOUNT_API_BASE_URL = value(forKey: "ACCOUNT_API_BASE_URL")
    static let ACCOUNT_BASE_URL = value(forKey: "ACCOUNT_BASE_URL")
    static let LUMO_API_BASE_URL = value(forKey: "LUMO_API_BASE_URL")
    static let LUMO_BASE_URL = value(forKey: "LUMO_BASE_URL")
    static let isLocalDevelopment = value(forKey: "ENABLE_LOCALHOST") == "YES"

    // MARK: - Private

    private static func value(forKey key: String) -> String {
        guard let value = Bundle.main.infoDictionary?[key] as? String else {
            fatalError("Can not find \(key) in Info.plist")
        }

        return value
    }
}

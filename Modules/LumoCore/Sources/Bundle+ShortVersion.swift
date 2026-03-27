import Foundation

extension Bundle {
    /// Returns the version of the app without build number e.g. "2.3.19"
    public var bundleShortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as! String
    }
}

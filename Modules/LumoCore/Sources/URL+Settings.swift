import UIKit

public extension URL {
    static let settings: URL = URL(string: UIApplication.openSettingsURLString).unsafelyUnwrapped
}

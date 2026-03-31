import UIKit

public extension URL {
    static var settings: URL {
        URL(string: UIApplication.openSettingsURLString).unsafelyUnwrapped
    }
}

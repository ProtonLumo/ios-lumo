import UIKit

public protocol DeviceProviding {
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }
}

extension UIDevice: DeviceProviding {}

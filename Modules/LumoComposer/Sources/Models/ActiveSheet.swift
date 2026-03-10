import Foundation

enum ActiveSheet: String, Identifiable, Equatable {
    case tools
    case modelSelection

    var id: String {
        rawValue
    }
}

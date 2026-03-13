enum ActiveSystemPicker: String, Identifiable, Equatable {
    case camera
    case files
    case photos

    var id: String {
        rawValue
    }
}

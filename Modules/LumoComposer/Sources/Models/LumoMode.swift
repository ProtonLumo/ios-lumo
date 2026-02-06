import Foundation

/// Represents Lumo's working state
///
/// This enum has only two states to keep the state machine simple:
/// - `idle`: Lumo is ready to accept new input
/// - `working`: Lumo is actively processing (thinking or responding)
enum LumoMode: String {
    case idle = "Idle"
    case working = "Working"
}

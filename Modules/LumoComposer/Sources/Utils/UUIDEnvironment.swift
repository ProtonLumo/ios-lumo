import Foundation

enum UUIDEnvironment {
    @TaskLocal
    static var uuid: () -> UUID = UUID.init
}

@testable import LumoComposer

enum AudioApplicationDeniedStub: AudioApplication {
    static func requestRecordPermission() async -> Bool { false }
}

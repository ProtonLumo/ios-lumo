@testable import LumoComposer

enum AudioApplicationGrantedStub: AudioApplication {
    static func requestRecordPermission() async -> Bool { true }
}

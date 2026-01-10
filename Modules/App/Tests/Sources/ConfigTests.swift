import Testing

@testable import LumoApp

struct ConfigTests {
    @Test(.enabled(if: Config.isLocalDevelopment))
    func testLocalEnvironment() {
        #expect(Config.ACCOUNT_API_BASE_URL == "https://account-api.proton.me")
        #expect(Config.ACCOUNT_BASE_URL == "https://account.proton.me")
        #expect(Config.LUMO_API_BASE_URL == "http://localhost:8080")
        #expect(Config.LUMO_BASE_URL == "http://localhost:8080")
    }

    @Test(.enabled(if: !Config.isLocalDevelopment))
    func testProductionEnvironment() {
        #expect(Config.ACCOUNT_API_BASE_URL == "https://account-api.proton.me")
        #expect(Config.ACCOUNT_BASE_URL == "https://account.proton.me")
        #expect(Config.LUMO_API_BASE_URL == "https://lumo-api.proton.me")
        #expect(Config.LUMO_BASE_URL == "https://lumo.proton.me")
    }
}

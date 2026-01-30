import Testing

@testable import LumoApp

struct ConfigTests {
    @Test(.enabled(if: Config.isLocalDevelopment))
    func testDevEnvironment() {
        #expect(Config.ACCOUNT_API_BASE_URL == "https://account-api.proton.me")
        #expect(Config.ACCOUNT_BASE_URL == "https://account.proton.me")
        #expect(Config.LUMO_API_BASE_URL == "https://lumo-api.proton.dev")
        #expect(Config.LUMO_BASE_URL == "https://lumo.proton.dev")
    }

    @Test(.enabled(if: !Config.isLocalDevelopment))
    func testProductionEnvironment() {
        #expect(Config.ACCOUNT_API_BASE_URL == "https://account-api.proton.me")
        #expect(Config.ACCOUNT_BASE_URL == "https://account.proton.me")
        #expect(Config.LUMO_API_BASE_URL == "https://lumo-api.proton.me")
        #expect(Config.LUMO_BASE_URL == "https://lumo.proton.me")
    }
}

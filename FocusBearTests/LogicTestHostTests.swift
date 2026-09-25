import XCTest
@testable import Focus_Bear

final class LogicTestHostTests: XCTestCase {
    func testExplicitFlagAndActualXCTestAreBothRequired() {
        XCTAssertTrue(LogicTestHost.shouldIsolate(environment: ["FOCUSBEAR_LOGIC_TEST_HOST": "1"],
                                                hasXCTest: true, isDebug: true))
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: ["FOCUSBEAR_LOGIC_TEST_HOST": "1"],
                                                 hasXCTest: false, isDebug: true))
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: [:], hasXCTest: true, isDebug: true))
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: ["FOCUSBEAR_LOGIC_TEST_HOST": "0"],
                                                 hasXCTest: true, isDebug: true))
    }

    func testReleaseBuildCannotEnterTheIsolatedHost() {
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: ["FOCUSBEAR_LOGIC_TEST_HOST": "1"],
                                                 hasXCTest: true, isDebug: false))
    }

    func testTelemetryOptOutAndGenericCIFlagsDoNotChangeStartup() {
        XCTAssertFalse(LogicTestHost.shouldIsolate(
            environment: ["CI": "true", "GITHUB_ACTIONS": "true", "FOCUSBEAR_DISABLE_TELEMETRY": "1"],
            hasXCTest: true, isDebug: true))
    }

    /// The host must not read the developer's login keychain: on the self-hosted runner that is the
    /// person's real account, and every ad-hoc CI build prompted them for it.
    func testTheHostHasNoCredentialsBecauseItNeverReadsTheKeychain() throws {
        XCTAssertTrue(LogicTestHost.isEnabled)
        let delegate = try XCTUnwrap(appdelegate)
        XCTAssertFalse(delegate.credentialsManager.hasValid(),
                       "an isolated host starts logged out; true here means it read the real keychain")
    }

    func testTheHostsCredentialsStoreKeepsWhatItIsGiven() {
        let store = LogicTestHost.CredentialsStore()
        XCTAssertNil(store.getEntry(forKey: "credentials"))
        XCTAssertTrue(store.setEntry(Data([1]), forKey: "credentials"))
        XCTAssertEqual(store.getEntry(forKey: "credentials"), Data([1]))
        XCTAssertTrue(store.deleteEntry(forKey: "credentials"))
        XCTAssertNil(store.getEntry(forKey: "credentials"))
    }

    func testSchemeActuallyStartsAnIsolatedHostWithBundledConfiguration() throws {
        XCTAssertTrue(LogicTestHost.isEnabled, "The TestAction must explicitly opt in to the logic host")
        let delegate = try XCTUnwrap(appdelegate)
        XCTAssertNil(delegate.timerBackgroundThread)
        XCTAssertNotNil(configjson["common"])
        XCTAssertNotNil(configjson["activityInfo"])
    }
}

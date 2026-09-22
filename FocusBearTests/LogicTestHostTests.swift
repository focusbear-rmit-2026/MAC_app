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

    func testSchemeActuallyStartsAnIsolatedHostWithBundledConfiguration() throws {
        XCTAssertTrue(LogicTestHost.isEnabled, "The TestAction must explicitly opt in to the logic host")
        let delegate = try XCTUnwrap(appdelegate)
        XCTAssertNil(delegate.timerBackgroundThread)
        XCTAssertNotNil(configjson["common"])
        XCTAssertNotNil(configjson["activityInfo"])
    }
}

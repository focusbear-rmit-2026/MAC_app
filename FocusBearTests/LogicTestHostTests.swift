import XCTest
@testable import Focus_Bear

final class LogicTestHostTests: XCTestCase {
    private static let DISABLED_ENVIRONMENT_VALUE = "0"
    func testLaunchRequiresEveryIsolationConditionWhenLogicTestingIsRequested() {
        let environment = [LogicTestHost.HOST_ENVIRONMENT_KEY: LogicTestHost.ENABLED_ENVIRONMENT_VALUE]
        for bundleIdentifier in [nil, LogicTestHost.SHIPPING_BUNDLE_IDENTIFIER, LogicTestHost.BUNDLE_IDENTIFIER] {
            for hasXCTest in [false, true] {
                for isDebug in [false, true] {
                    XCTAssertEqual(LogicTestHost.shouldPermitLaunch(
                        environment: environment, bundleIdentifier: bundleIdentifier,
                        hasXCTest: hasXCTest, isDebug: isDebug),
                        bundleIdentifier == LogicTestHost.BUNDLE_IDENTIFIER && hasXCTest && isDebug)
                }
            }
        }
    }

    func testIsolatedBundleCannotLaunchWithoutTheLogicHostFlag() {
        for environment in [[:], [LogicTestHost.HOST_ENVIRONMENT_KEY: Self.DISABLED_ENVIRONMENT_VALUE]] {
            for hasXCTest in [false, true] {
                XCTAssertFalse(LogicTestHost.shouldPermitLaunch(
                    environment: environment, bundleIdentifier: LogicTestHost.BUNDLE_IDENTIFIER,
                    hasXCTest: hasXCTest, isDebug: true))
            }
        }
    }

    func testNormalAndUITestLaunchesRemainAllowedWithoutLogicHostIntent() {
        for bundleIdentifier in [nil, LogicTestHost.SHIPPING_BUNDLE_IDENTIFIER, "com.App.EarnYourScreentime.uitests"] {
            for hasXCTest in [false, true] {
                for isDebug in [false, true] {
                    XCTAssertTrue(LogicTestHost.shouldPermitLaunch(
                        environment: [:], bundleIdentifier: bundleIdentifier,
                        hasXCTest: hasXCTest, isDebug: isDebug))
                }
            }
        }
    }

    func testTheActualHostUsesAnIsolatedBundleAndSharedSuite() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, LogicTestHost.BUNDLE_IDENTIFIER)
        XCTAssertTrue(fbSharedDefaultsSuiteName.hasSuffix(LogicTestHost.BUNDLE_IDENTIFIER_SUFFIX))
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes"))
    }

    func testSharedSuiteIsolationDoesNotChangeShippingOrOtherBundles() {
        let productionSuite = "test-team.group.com.focusbear.fbmac"
        XCTAssertEqual(LogicTestHost.sharedDefaultsSuiteName(
            productionSuiteName: productionSuite, bundleIdentifier: LogicTestHost.BUNDLE_IDENTIFIER),
            productionSuite + LogicTestHost.BUNDLE_IDENTIFIER_SUFFIX)
        for otherBundle in [nil, LogicTestHost.SHIPPING_BUNDLE_IDENTIFIER, "unrelated.bundle"] {
            XCTAssertEqual(LogicTestHost.sharedDefaultsSuiteName(
                productionSuiteName: productionSuite, bundleIdentifier: otherBundle), productionSuite)
        }
    }

    func testExplicitFlagAndActualXCTestAreBothRequired() {
        XCTAssertTrue(LogicTestHost.shouldIsolate(environment: [LogicTestHost.HOST_ENVIRONMENT_KEY: LogicTestHost.ENABLED_ENVIRONMENT_VALUE],
                                                hasXCTest: true, isDebug: true))
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: [LogicTestHost.HOST_ENVIRONMENT_KEY: LogicTestHost.ENABLED_ENVIRONMENT_VALUE],
                                                 hasXCTest: false, isDebug: true))
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: [:], hasXCTest: true, isDebug: true))
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: [LogicTestHost.HOST_ENVIRONMENT_KEY: Self.DISABLED_ENVIRONMENT_VALUE],
                                                 hasXCTest: true, isDebug: true))
    }

    func testReleaseBuildCannotEnterTheIsolatedHost() {
        XCTAssertFalse(LogicTestHost.shouldIsolate(environment: [LogicTestHost.HOST_ENVIRONMENT_KEY: LogicTestHost.ENABLED_ENVIRONMENT_VALUE],
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

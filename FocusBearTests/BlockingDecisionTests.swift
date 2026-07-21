//
//  BlockingDecisionTests.swift
//  FocusBearTests
//
//  Tests for getBlockedUrlsToBlock() and getBlockedAppsToBlock() in globalFile.swift
//  Issue: Focus-Bear/Mac-App#1625
//

@testable import Focus_Bear
import XCTest

class BlockingDecisionTests: XCTestCase {

    private let testSuite = "BlockingDecisionTests"

    override func setUp() {
        super.setUp()
        // Reset all global state to known defaults before each test
        isFocusBreakOn = false
        currentState   = ._NOTHING_
        isExpired      = false
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = false
        SettingsManagerObject.arrBlockedUrls  = []
        SettingsManagerObject.arrBlockedApps  = []
        // Clear the DoNotBlock pref
        UserDefaults.standard.removeObject(
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
    }

    override func tearDown() {
        // Restore globals to safe defaults
        isFocusBreakOn = false
        currentState   = ._NOTHING_
        isExpired      = false
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = false
        SettingsManagerObject.arrBlockedUrls = []
        SettingsManagerObject.arrBlockedApps = []
        UserDefaults.standard.removeObject(
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        super.tearDown()
    }

    // MARK: - getBlockedUrlsToBlock

    func test_blockedUrls_normalState_returnsFullList() {
        SettingsManagerObject.arrBlockedUrls = ["facebook.com", "twitter.com", "reddit.com"]
        let result = getBlockedUrlsToBlock()
        XCTAssertEqual(result, ["facebook.com", "twitter.com", "reddit.com"])
    }

    func test_blockedUrls_emptyList_returnsEmpty() {
        SettingsManagerObject.arrBlockedUrls = []
        let result = getBlockedUrlsToBlock()
        XCTAssertTrue(result.isEmpty)
    }

    func test_blockedUrls_withCustomScheduleAndFocusBreak_andDoNotBlockEnabled_returnsEmpty() {
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = true
        isFocusBreakOn = true
        UserDefaults.standard.set(true,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        SettingsManagerObject.arrBlockedUrls = ["facebook.com"]

        let result = getBlockedUrlsToBlock()
        XCTAssertTrue(result.isEmpty,
            "Should return empty list when custom schedule is on, focus break is on, and DoNotBlock pref is set")
    }

    func test_blockedUrls_withCustomScheduleAndFocusBreak_doNotBlockDisabled_returnsUrls() {
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = true
        isFocusBreakOn = true
        UserDefaults.standard.set(false,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        SettingsManagerObject.arrBlockedUrls = ["facebook.com"]

        let result = getBlockedUrlsToBlock()
        XCTAssertFalse(result.isEmpty,
            "Should still block when DoNotBlock pref is explicitly false")
    }

    func test_blockedUrls_withMicroBreakState_andDoNotBlockEnabled_returnsEmpty() {
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = true
        currentState = ._MICRO_BREAK_
        UserDefaults.standard.set(true,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        SettingsManagerObject.arrBlockedUrls = ["facebook.com"]

        let result = getBlockedUrlsToBlock()
        XCTAssertTrue(result.isEmpty,
            "Should return empty list in micro-break state when DoNotBlock pref is set")
    }

    func test_blockedUrls_expiredApp_limitsCount() {
        isExpired = true
        let manyUrls = (0..<10).map { "site\($0).com" }
        SettingsManagerObject.arrBlockedUrls = manyUrls

        let result = getBlockedUrlsToBlock()
        XCTAssertEqual(result.count, alwaysBlockedUrlsCountInExpireApp,
            "Expired app should cap blocked URL count to alwaysBlockedUrlsCountInExpireApp")
    }

    func test_blockedUrls_expiredApp_fewerThanLimit_returnsAll() {
        isExpired = true
        SettingsManagerObject.arrBlockedUrls = ["site1.com"]

        let result = getBlockedUrlsToBlock()
        XCTAssertEqual(result.count, 1,
            "Expired app with fewer URLs than cap should return all URLs")
    }

    // MARK: - getBlockedAppsToBlock

    func test_blockedApps_normalState_returnsFullList() {
        SettingsManagerObject.arrBlockedApps = ["Twitter", "Facebook", "Reddit"]
        let result = getBlockedAppsToBlock()
        XCTAssertEqual(result, ["Twitter", "Facebook", "Reddit"])
    }

    func test_blockedApps_emptyList_returnsEmpty() {
        SettingsManagerObject.arrBlockedApps = []
        let result = getBlockedAppsToBlock()
        XCTAssertTrue(result.isEmpty)
    }

    func test_blockedApps_withCustomScheduleAndFocusBreak_andDoNotBlockEnabled_returnsEmpty() {
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = true
        isFocusBreakOn = true
        UserDefaults.standard.set(true,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        SettingsManagerObject.arrBlockedApps = ["Twitter"]

        let result = getBlockedAppsToBlock()
        XCTAssertTrue(result.isEmpty,
            "Should return empty list when custom schedule is on, focus break is on, and DoNotBlock pref is set")
    }

    func test_blockedApps_withMicroBreakState_andDoNotBlockEnabled_returnsEmpty() {
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = true
        currentState = ._MICRO_BREAK_
        UserDefaults.standard.set(true,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        SettingsManagerObject.arrBlockedApps = ["Twitter"]

        let result = getBlockedAppsToBlock()
        XCTAssertTrue(result.isEmpty,
            "Should return empty list in micro-break state when DoNotBlock pref is set")
    }

    func test_blockedApps_expiredApp_limitsCount() {
        isExpired = true
        let manyApps = (0..<10).map { "App\($0)" }
        SettingsManagerObject.arrBlockedApps = manyApps

        let result = getBlockedAppsToBlock()
        XCTAssertEqual(result.count, alwaysBlockedUrlsCountInExpireApp,
            "Expired app should cap blocked app count to alwaysBlockedUrlsCountInExpireApp")
    }

    func test_blockedApps_noCustomSchedule_returnsAppsRegardlessOfBreakState() {
        customBlockingScheduleManagerObj.isAnyCustomScheduleOn = false
        isFocusBreakOn = true
        UserDefaults.standard.set(true,
            forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
        SettingsManagerObject.arrBlockedApps = ["Twitter", "Facebook"]

        let result = getBlockedAppsToBlock()
        XCTAssertEqual(result.count, 2,
            "Break-state early return only applies when a custom schedule is active")
    }
}

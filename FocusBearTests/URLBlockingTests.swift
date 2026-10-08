//
//  URLBlockingTests.swift
//  Focus BearTests
//
//  Created by Devin AI on 17/01/26.
//

@testable import Focus_Bear
import XCTest

class URLBlockingTests: XCTestCase {
    
    var validation: urlValidation!
    
    override func setUp() {
        super.setUp()
        validation = urlValidation()
    }
    
    override func tearDown() {
        validation = nil
        super.tearDown()
    }
    
    func test_url_in_always_blocked_list() {
        let alwaysBlockedURLs = ["facebook.com", "twitter.com"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://www.facebook.com", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertTrue(result)
    }
    
    func test_url_not_in_always_blocked_list() {
        let alwaysBlockedURLs = ["facebook.com", "twitter.com"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://www.github.com", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertFalse(result)
    }
    
    func test_url_in_allowed_list() {
        let allowedURLs = ["github.com", "stackoverflow.com"]
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://github.com/Focus-Bear", allowedURLs: allowedURLs)
        XCTAssertTrue(result)
    }
    
    func test_url_not_in_allowed_list() {
        let allowedURLs = ["github.com", "stackoverflow.com"]
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://www.facebook.com", allowedURLs: allowedURLs)
        XCTAssertFalse(result)
    }
    
    func test_should_block_url_when_in_always_blocked_list() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.facebook.com",
            alwaysBlockedURLs: ["facebook.com"],
            allowedURLs: ["facebook.com"],
            isAllowedListApproach: false
        )
        XCTAssertTrue(result, "URL in always blocked list should be blocked")
    }
    
    func test_should_block_url_when_not_in_allowed_list_with_allowed_list_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.twitter.com",
            alwaysBlockedURLs: [],
            allowedURLs: ["github.com", "stackoverflow.com"],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result, "URL not in allowed list should be blocked when using allowed list approach")
    }
    
    func test_should_not_block_url_when_in_allowed_list_with_allowed_list_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://github.com/Focus-Bear",
            alwaysBlockedURLs: [],
            allowedURLs: ["github.com"],
            isAllowedListApproach: true
        )
        XCTAssertFalse(result, "URL in allowed list should not be blocked when using allowed list approach")
    }
    
    func test_should_not_block_url_when_not_using_allowed_list_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.twitter.com",
            alwaysBlockedURLs: [],
            allowedURLs: [],
            isAllowedListApproach: false
        )
        XCTAssertFalse(result, "URL should not be blocked when not using allowed list approach and not in blocked list")
    }
    
    func test_always_blocked_takes_priority_over_allowed() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://www.facebook.com",
            alwaysBlockedURLs: ["facebook.com"],
            allowedURLs: ["facebook.com"],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result, "Always blocked should take priority over allowed list")
    }
    
    func test_url_with_wildcard_in_blocked_list() {
        let alwaysBlockedURLs = ["*facebook*"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://m.facebook.com/messages", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertTrue(result)
    }
    
    func test_url_with_subdomain_blocked() {
        let alwaysBlockedURLs = ["*.facebook.com"]
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://m.facebook.com", alwaysBlockedURLs: alwaysBlockedURLs)
        XCTAssertTrue(result)
    }
    
    func test_empty_always_blocked_list() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://www.facebook.com", alwaysBlockedURLs: [])
        XCTAssertFalse(result)
    }
    
    func test_empty_allowed_list() {
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://www.github.com", allowedURLs: [])
        XCTAssertFalse(result)
    }

    // =========================================================================
    // ADDED: case-insensitivity, keywords, paths, multi-entry lists
    // =========================================================================
    func test_always_blocked_is_case_insensitive() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "HTTPS://TWITTER.COM", alwaysBlockedURLs: ["twitter.com"])
        XCTAssertTrue(result)
    }

    func test_always_blocked_matches_keyword_without_dot() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "https://m.facebook.com/messages", alwaysBlockedURLs: ["facebook"])
        XCTAssertTrue(result)
    }

    func test_always_blocked_empty_url_does_not_match() {
        let result = URLBlockingHelper.isURLInAlwaysBlockedList(url: "", alwaysBlockedURLs: ["facebook.com"])
        XCTAssertFalse(result)
    }

    func test_allowed_list_matches_url_with_path() {
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://github.com/Focus-Bear/repo", allowedURLs: ["github.com"])
        XCTAssertTrue(result)
    }

    func test_allowed_list_matches_second_entry() {
        let result = URLBlockingHelper.isURLInAllowedList(url: "https://stackoverflow.com/q/1", allowedURLs: ["github.com", "stackoverflow.com"])
        XCTAssertTrue(result)
    }

    // =========================================================================
    // ADDED: shouldBlockURL decision matrix
    // =========================================================================
    func test_should_block_url_matches_blocked_keyword() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://reddit.com",
            alwaysBlockedURLs: ["reddit"],
            allowedURLs: [],
            isAllowedListApproach: false
        )
        XCTAssertTrue(result, "Keyword in always-blocked list should block the URL")
    }

    func test_should_not_block_url_in_allowed_list_with_path() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://github.com/explore",
            alwaysBlockedURLs: [],
            allowedURLs: ["github.com"],
            isAllowedListApproach: true
        )
        XCTAssertFalse(result, "URL whose domain is in the allowed list should not be blocked")
    }

    /// With the allowed-list approach an EMPTY allowed list blocks everything
    /// (nothing is whitelisted). Contrast with `test_empty_pattern_matches_any_url`
    /// in validationTest: an empty *list* is not the same as an empty *pattern*.
    func test_should_block_url_when_allowed_list_is_empty_in_allowed_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://github.com",
            alwaysBlockedURLs: [],
            allowedURLs: [],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result)
    }

    func test_should_not_block_unlisted_url_without_allowed_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://anything.com",
            alwaysBlockedURLs: ["reddit.com"],
            allowedURLs: [],
            isAllowedListApproach: false
        )
        XCTAssertFalse(result, "Without allowed-list approach, only always-blocked URLs are blocked")
    }

    func test_always_blocked_overrides_allowed_in_allowed_approach() {
        let result = URLBlockingHelper.shouldBlockURL(
            url: "https://x.com",
            alwaysBlockedURLs: ["x.com"],
            allowedURLs: ["x.com"],
            isAllowedListApproach: true
        )
        XCTAssertTrue(result, "Always-blocked should win even when the URL is also in the allowed list")
    }

    // MARK: Focus Bear's own pages (report 2026-09-21_10-04-40)
    //
    // The block page blocked the block page. A previous run's embedded server keeps its port until
    // it is reaped, so each launch picks a higher one; the exemption pinned only the CURRENT port,
    // so a block page a browser was still showing from an earlier run stopped being recognised as
    // ours. The screenshot caught the recursion mid-nest: localhost:50504 blocking localhost:50503,
    // which was itself blocking ankiweb.net.

    func testTheBlockPageIsOursOnEveryPortTheAppCanPick() {
        for port in [50501, 50502, 50503, 50504, 50550] {
            XCTAssertTrue(isFocusBearLocalPage("http://localhost:\(port)/?old_url=https%3A%2F%2Fexample.com"),
                          "port \(port) is inside the range firstAvailablePort scans")
        }
    }

    func testTheRecursionFromTheReport() {
        let inner = "http://localhost:50503/?old_url=https%3A%2F%2Fapps.ankiweb.net%2F%23download"
        let outer = "http://localhost:50504/?old_url=" + inner.addingPercentEncoding(
            withAllowedCharacters: .alphanumerics)!
        XCTAssertTrue(isFocusBearLocalPage(inner))
        XCTAssertTrue(isFocusBearLocalPage(outer), "the outer page must not block the inner one")
    }

    func testLoopbackSpellingsAndSchemelessUrls() {
        XCTAssertTrue(isFocusBearLocalPage("http://127.0.0.1:50501/"))
        XCTAssertTrue(isFocusBearLocalPage("localhost:50504/?old_url=x"))
        XCTAssertTrue(isFocusBearLocalPage("HTTP://LOCALHOST:50502/"))
    }

    /// The reason this is parsed rather than matched as a substring: a page that merely NAMES the
    /// loopback address must not inherit the exemption, or any site could opt itself out of
    /// blocking by putting `localhost:50504` in its query string.
    func testASiteThatMerelyMentionsTheLoopbackAddressIsNotOurs() {
        XCTAssertFalse(isFocusBearLocalPage("https://example.com/?redirect=localhost:50504"))
        XCTAssertFalse(isFocusBearLocalPage("https://localhost.evil.com:50504/"))
        XCTAssertFalse(isFocusBearLocalPage("https://evil.com/localhost:50504"))
    }

    func testPortsOutsideTheAppsRangeAreNotOurs() {
        XCTAssertFalse(isFocusBearLocalPage("http://localhost:3000/"), "a dev server is not ours")
        XCTAssertFalse(isFocusBearLocalPage("http://localhost:50500/"), "just below the range")
        XCTAssertFalse(isFocusBearLocalPage("http://localhost:50551/"), "just above the range")
        XCTAssertFalse(isFocusBearLocalPage("http://localhost/"), "no port at all")
    }

    func testEmptyAndMalformedInputIsNotOurs() {
        XCTAssertFalse(isFocusBearLocalPage(""))
        XCTAssertFalse(isFocusBearLocalPage("   "))
        XCTAssertFalse(isFocusBearLocalPage("not a url"))
    }

}

// These tests use captured AppleScript error shapes, without executing AppleScript or touching
// the current user's Automation permissions/preferences.
extension URLBlockingTests {
    func testNilDescriptorStillReportsChromeAutomationDenial() {
        let errors: NSDictionary = [
            "NSAppleScriptErrorNumber": NSNumber(value: -1743),
            "NSAppleScriptErrorAppName": "Google Chrome",
            "NSAppleScriptErrorMessage": "Not authorized to send Apple events to Google Chrome."
        ]
        XCTAssertEqual(BrowserScriptStringResult.interpret(value: nil, hasDescriptor: false, errors: errors),
                       .automationDenied(application: "Google Chrome"))
    }

    func testStringErrorCodeTakesPriorityOverAResultDescriptor() {
        let errors: NSDictionary = ["NSAppleScriptErrorNumber": "-1743", "NSAppleScriptErrorAppName": "Safari"]
        XCTAssertEqual(BrowserScriptStringResult.interpret(value: "", hasDescriptor: true, errors: errors),
                       .automationDenied(application: "Safari"))
    }

    func testTimeoutAndMissingDescriptorRemainUnknownRatherThanDenied() {
        XCTAssertEqual(BrowserScriptStringResult.interpret(value: nil, hasDescriptor: false, errors: nil), .unavailable)
        let timeout: NSDictionary = ["NSAppleScriptErrorNumber": -1712, "NSAppleScriptErrorAppName": "Google Chrome"]
        XCTAssertEqual(BrowserScriptStringResult.interpret(value: nil, hasDescriptor: false, errors: timeout), .unavailable)
    }

    func testBrowserProfilePickerWithAnEmptyDescriptorIsNotARevokedPermission() {
        XCTAssertEqual(BrowserScriptStringResult.interpret(value: nil, hasDescriptor: true, errors: nil), .value(""))
    }

    func testPermissionDenialChangesOnlyTheAffectedBrowserAndPreservesOtherFields() throws {
        let rows: [[String: Any]] = [
            ["browser": BROWSER._GOOGLE_CHROME_.rawValue, "isEnabled": true, "otherSetting": "keep"],
            ["browser": BROWSER._SAFARI_.rawValue, "isEnabled": true]
        ]
        let updated = try XCTUnwrap(BrowserPermissionRecords.updating(rows, browser: ._GOOGLE_CHROME_, enabled: false))
        XCTAssertEqual(updated[0]["isEnabled"] as? Bool, false)
        XCTAssertEqual(updated[0]["otherSetting"] as? String, "keep")
        XCTAssertEqual(updated[1]["isEnabled"] as? Bool, true)
        XCTAssertEqual(rows[0]["isEnabled"] as? Bool, true, "Do not mutate the caller's snapshot")
        XCTAssertNil(BrowserPermissionRecords.updating(updated, browser: ._GOOGLE_CHROME_, enabled: false),
                     "Repeated denied polls should not keep writing the same preference")
    }

    func testPermissionReadCanRecoverOrCreateAnAbsentBrowserRecord() throws {
        let denied = try XCTUnwrap(BrowserPermissionRecords.updating([], browser: ._GOOGLE_CHROME_, enabled: false))
        XCTAssertEqual(denied.count, 1)
        XCTAssertEqual(denied[0]["isEnabled"] as? Bool, false)
        let restored = try XCTUnwrap(BrowserPermissionRecords.updating(denied, browser: ._GOOGLE_CHROME_, enabled: true))
        XCTAssertEqual(restored[0]["isEnabled"] as? Bool, true)
        XCTAssertNil(BrowserPermissionRecords.updating(restored, browser: ._GOOGLE_CHROME_, enabled: true))
    }

    func testRuntimeDenialIsReportedEvenWhenPreferencesWereAlreadyDisabled() {
        let saved: [[String: Any]] = [["browser": BROWSER._GOOGLE_CHROME_.rawValue, "isEnabled": false]]
        XCTAssertNil(BrowserPermissionRecords.updating(saved, browser: ._GOOGLE_CHROME_, enabled: false))
        var evidence = BrowserAutomationDenials()
        XCTAssertTrue(evidence.browsers.isEmpty, "Saved disabled/unknown status is not a confirmed runtime denial")
        XCTAssertTrue(evidence.record(browser: ._GOOGLE_CHROME_, enabled: false))
        XCTAssertFalse(evidence.record(browser: ._GOOGLE_CHROME_, enabled: false), "Repeated denials must deduplicate")
        XCTAssertEqual(evidence.browsers, [._GOOGLE_CHROME_])
    }

    func testAnotherBrowsersSuccessCannotClearChromeDenial() {
        var evidence = BrowserAutomationDenials()
        evidence.record(browser: ._GOOGLE_CHROME_, enabled: false)
        evidence.record(browser: ._SAFARI_, enabled: false)
        XCTAssertTrue(evidence.record(browser: ._SAFARI_, enabled: true))
        XCTAssertEqual(evidence.browsers, [._GOOGLE_CHROME_])
        XCTAssertFalse(evidence.record(browser: ._SAFARI_, enabled: true))
        XCTAssertTrue(evidence.record(browser: ._GOOGLE_CHROME_, enabled: true))
        XCTAssertTrue(evidence.browsers.isEmpty)
    }
}

// The System Events gate must not turn an unknown/timeout result into a denial or send a timed
// AppleScript while the explicit consent request is still on screen. No OS permission probes run.
extension URLBlockingTests {
    func testSystemEventsPermissionResultDistinguishesDeniedConsentRequiredAndUnknown() {
        XCTAssertEqual(SystemEventsAutomationResult(status: 0), .granted)
        XCTAssertEqual(SystemEventsAutomationResult(status: -1743), .denied)
        XCTAssertEqual(SystemEventsAutomationResult(status: -1744), .consentRequired)
        for status: Int32 in [-600, -1712, -1] {
            XCTAssertEqual(SystemEventsAutomationResult(status: status), .unknown)
            XCTAssertFalse(SystemEventsAutomationResult(status: status).permitsRuntimeScript(requestInFlight: false))
        }
    }

    func testSystemEventsScriptsWaitForExplicitConsentRequestEvenWithAnEarlierGrant() {
        XCTAssertTrue(SystemEventsAutomationResult.granted.permitsRuntimeScript(requestInFlight: false))
        for result in [SystemEventsAutomationResult.granted, .denied, .consentRequired, .unknown] {
            XCTAssertFalse(result.permitsRuntimeScript(requestInFlight: true))
        }
        XCTAssertFalse(SystemEventsAutomationResult.denied.permitsRuntimeScript(requestInFlight: false))
        XCTAssertFalse(SystemEventsAutomationResult.consentRequired.permitsRuntimeScript(requestInFlight: false))
    }
}

/// A trailing unescaped backslash makes `NSPredicate` raise `NSInvalidArgumentException`. That is an
/// Objective-C exception, so Swift cannot catch it — the app terminates. Most callers wrap the
/// user's entry as `*entry*` so it is never last, but `isUrlValid`'s `file://` branch passes the
/// entry through unwrapped, so an allow-list entry ending in a backslash crashed Focus Bear.
final class WildcardPatternSafetyTests: XCTestCase {
    func testATrailingBackslashCannotReachNSPredicateUnescaped() {
        XCTAssertEqual(escapedForLike("file:///Users/me/folder\\"), "file:///Users/me/folder\\\\")
        // Already escaped, so it is left alone rather than doubled again.
        XCTAssertEqual(escapedForLike("file:///Users/me/folder\\\\"), "file:///Users/me/folder\\\\")
        XCTAssertEqual(escapedForLike("a\\\\\\"), "a\\\\\\\\")
    }

    func testOrdinaryPatternsAreUntouched() {
        XCTAssertEqual(escapedForLike("*example.com*"), "*example.com*")
        XCTAssertEqual(escapedForLike(""), "")
        XCTAssertEqual(escapedForLike("a\\b"), "a\\b", "A backslash that is not trailing is already escaping something")
    }

    /// The crash this guards against: without the escape this call terminates the process, so a
    /// green run of this test is the evidence.
    func testTheUnwrappedFileBranchNoLongerCrashes() {
        XCTAssertFalse(wildcard("file:///Users/me/x", pattern: "file:///Users/me/folder\\"))
    }
}
